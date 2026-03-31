#!/usr/bin/env python3
"""
Convert IMS Common Cartridge export to structured Markdown files.

This script is designed to be placed inside an extracted .imscc directory
(alongside imsmanifest.xml) and run from that directory.

It reads imsmanifest.xml, parses the course module structure, extracts
content from XML/HTML resources, classifies items (page, assignment,
quiz, external), and writes structured Markdown files to ./content/.

Usage:
    cd /path/to/extracted-imscc/
    python imscc-to-markdown.py
"""

import os
import re
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from html import unescape

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
# Use a relative output path to avoid Windows 260-char path limit.
# The bash wrapper always cd's into BASE_DIR before running this script.
OUTPUT_DIR = os.path.join(".", "content")

# ── HTML to Markdown converter ──────────────────────────────────────────

class HTMLToMarkdown(HTMLParser):
    def __init__(self):
        super().__init__()
        self.result = []
        self.current_href = None
        self.link_text = []
        self.in_link = False
        self.links = []  # collect (label, url) pairs

    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)
        if tag == 'a':
            self.in_link = True
            self.current_href = attrs_dict.get('href', '')
            self.link_text = []
        elif tag == 'br':
            self.result.append('\n')
        elif tag == 'p':
            pass
        elif tag == 'strong' or tag == 'b':
            self.result.append('**')
        elif tag == 'em' or tag == 'i':
            self.result.append('*')
        elif tag == 'ul':
            self.result.append('\n')
        elif tag == 'ol':
            self.result.append('\n')
        elif tag == 'li':
            self.result.append('- ')
        elif tag == 'h1':
            self.result.append('\n# ')
        elif tag == 'h2':
            self.result.append('\n## ')
        elif tag == 'h3':
            self.result.append('\n### ')
        elif tag == 'span':
            pass
        elif tag == 'img':
            src = attrs_dict.get('src', '')
            alt = attrs_dict.get('alt', 'image')
            self.result.append(f'![{alt}]({src})')

    def handle_endtag(self, tag):
        if tag == 'a':
            label = ''.join(self.link_text).strip()
            href = self.current_href or ''
            if not label:
                label = 'Link'
            # Clean canvas references
            if '$CANVAS_OBJECT_REFERENCE$' in href:
                href = ''
            if href:
                self.links.append((label, href))
                self.result.append(f'[{label}]({href})')
            else:
                # For canvas-internal refs, just skip the broken link
                pass
            self.in_link = False
            self.current_href = None
            self.link_text = []
        elif tag == 'p':
            self.result.append('\n\n')
        elif tag == 'strong' or tag == 'b':
            self.result.append('**')
        elif tag == 'em' or tag == 'i':
            self.result.append('*')
        elif tag == 'li':
            self.result.append('\n')
        elif tag in ('h1', 'h2', 'h3'):
            self.result.append('\n')

    def handle_data(self, data):
        if self.in_link:
            self.link_text.append(data)
            return  # Don't add to result while inside a link
        self.result.append(data)

    def get_markdown(self):
        text = ''.join(self.result)
        # Clean up multiple newlines
        text = re.sub(r'\n{3,}', '\n\n', text)
        # Clean up "Click here" patterns with links
        text = re.sub(r'Click\s*\[([^\]]+)\]\(([^)]+)\)\s*to\s+view', r'View', text)
        text = re.sub(r'Click\s*\[([^\]]+)\]\(([^)]+)\)\s*to\s+begin', r'Begin', text)
        text = re.sub(r'Click\s*\[([^\]]+)\]\(([^)]+)\)\s*to\s+join', r'Join via', text)
        # Clean up orphaned "Click " before link-less text
        text = re.sub(r'Click\s+to\s+view\b', 'View', text)
        text = re.sub(r'Click\s+to\s+begin\b', 'Begin', text)
        return text.strip()

    def get_links(self):
        return self.links


def html_to_markdown(html_str):
    """Convert HTML string to Markdown, return (text, links)."""
    if not html_str:
        return '', []
    parser = HTMLToMarkdown()
    parser.feed(unescape(html_str))
    return parser.get_markdown(), parser.get_links()


def extract_links_from_html(html_str):
    """Extract all links from HTML."""
    links = []
    if not html_str:
        return links
    pattern = r'<a[^>]+href=["\']([^"\']+)["\'][^>]*>(.*?)</a>'
    for match in re.finditer(pattern, unescape(html_str), re.DOTALL):
        url = match.group(1)
        label = re.sub(r'<[^>]+>', '', match.group(2)).strip()
        if not label:
            label = 'Link'
        if '$CANVAS_OBJECT_REFERENCE$' not in url:
            links.append((label, url))
    return links


def slugify(text):
    """Convert title to a filename-safe slug."""
    text = text.lower().strip()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_]+', '-', text)
    text = re.sub(r'-+', '-', text)
    text = text.strip('-')
    return text


# ── Parse manifest ──────────────────────────────────────────────────────

NS = {
    'cc': 'http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1',
    'lom': 'http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource',
    'lomimscc': 'http://ltsc.ieee.org/xsd/imsccv1p1/LOM/manifest',
}

def parse_manifest():
    """Parse imsmanifest.xml, return modules and resource map."""
    tree = ET.parse(os.path.join(BASE_DIR, 'imsmanifest.xml'))
    root = tree.getroot()

    # Build resource map: identifier -> resource element
    resources = {}
    for res in root.findall('.//cc:resources/cc:resource', NS):
        rid = res.get('identifier')
        rtype = res.get('type', '')
        href = res.get('href', '')
        resources[rid] = {
            'type': rtype,
            'href': href,
            'files': [f.get('href') for f in res.findall('cc:file', NS)],
        }

    # Build module hierarchy from organization
    modules = []
    org = root.find('.//cc:organizations/cc:organization', NS)
    if org is None:
        return modules, resources

    learning_modules = org.find('cc:item[@identifier="LearningModules"]', NS)
    if learning_modules is None:
        learning_modules = org

    for module_item in learning_modules.findall('cc:item', NS):
        module_title = module_item.find('cc:title', NS)
        module_title = module_title.text.strip() if module_title is not None else 'Untitled Module'

        items = []
        for child in module_item.findall('cc:item', NS):
            title_el = child.find('cc:title', NS)
            title = title_el.text.strip() if title_el is not None else 'Untitled'
            identifierref = child.get('identifierref', '')

            # Check if this is a subheader (no identifierref)
            if not identifierref:
                items.append({
                    'title': title,
                    'identifierref': '',
                    'type': 'subheader',
                })
                continue

            items.append({
                'title': title,
                'identifierref': identifierref,
            })

        modules.append({
            'title': module_title,
            'items': items,
        })

    return modules, resources


# ── Content extraction ──────────────────────────────────────────────────

def read_xml_topic(filepath):
    """Read a topic XML file (imsdt), return title and HTML text."""
    try:
        tree = ET.parse(filepath)
        root = tree.getroot()
        # Handle namespace
        ns = {'dt': 'http://www.imsglobal.org/xsd/imsccv1p1/imsdt_v1p1'}
        title_el = root.find('dt:title', ns)
        text_el = root.find('dt:text', ns)
        title = title_el.text.strip() if title_el is not None and title_el.text else ''
        text = text_el.text if text_el is not None and text_el.text else ''
        return title, text
    except Exception:
        return '', ''


def read_weblink(filepath):
    """Read a webLink XML file, return title and URL."""
    try:
        tree = ET.parse(filepath)
        root = tree.getroot()
        ns = {'wl': 'http://www.imsglobal.org/xsd/imsccv1p1/imswl_v1p1'}
        title_el = root.find('wl:title', ns)
        url_el = root.find('wl:url', ns)
        title = title_el.text.strip() if title_el is not None and title_el.text else ''
        url = url_el.get('href', '') if url_el is not None else ''
        return title, url
    except Exception:
        return '', ''


def read_html_assignment(filepath):
    """Read an assignment HTML file, return title and body HTML."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        # Extract title
        title_match = re.search(r'<title>(.*?)</title>', content, re.DOTALL)
        title = title_match.group(1).strip() if title_match else ''
        # Remove "Assignment: " prefix from title
        title = re.sub(r'^Assignment:\s*', '', title)
        # Extract body content
        body_match = re.search(r'<body>(.*?)</body>', content, re.DOTALL)
        body = body_match.group(1).strip() if body_match else ''
        return title, body
    except Exception:
        return '', ''


def read_quiz_meta(quiz_dir):
    """Read quiz assessment_meta.xml, return title and description."""
    meta_path = os.path.join(quiz_dir, 'assessment_meta.xml')
    try:
        tree = ET.parse(meta_path)
        root = tree.getroot()
        ns = {'q': 'http://canvas.instructure.com/xsd/cccv1p0'}
        title_el = root.find('q:title', ns)
        desc_el = root.find('q:description', ns)
        title = title_el.text.strip() if title_el is not None and title_el.text else ''
        desc = desc_el.text if desc_el is not None and desc_el.text else ''
        return title, desc
    except Exception:
        return '', ''


# ── Content type classification ─────────────────────────────────────────

ASSIGNMENT_KEYWORDS = [
    'my first', 'fizzbuzz', 'shopping cart', 'number list',
    'string manipulation', 'numbers triangles tables', 'debugging',
    'tic tac toe', 'dice', 'parsing strings', 'string array',
    'phone number factory', 'tdd animal', 'product manager',
    'phonebook', 'my collection', 'arcade', 'learner lab',
    'abstract shapes', 'pet owner', 'playlist', 'wombats', 'greeps',
    'broken crud', 'blackjack', 'migration', 'crud controller',
    'mockito muffin', 'randomutility', 'filereadwrite',
    'first collaboration', 'first fork', 'first repository',
    'first github page', 'first person', 'first project',
    'first style', 'first form', 'first table', 'first list',
    'first database connection',
]

QUIZ_KEYWORDS = ['quiz']

PAGE_KEYWORDS = [
    'what is', 'types', 'operators', 'conditionals', 'functions',
    'loops', 'classes', 'modules', 'installation', 'install',
    'upgrade', 'configuring', 'environment set up', 'walkthrough',
    'collection', 'arraylist', 'maps', 'solid', 'design pattern',
    'encapsulation', 'inheritance', 'foundations', 'enums',
    'http verbs', 'restful', 'model, view', 'spring annotations',
    'mockito', 'untestable', 'fundamental test', 'object-state',
    'abstracting test', 'console input', 'file read', 'file parse',
    'exceptions', 'glossary', 'intro to sql', 'intro to acid',
    'table schemas', 'schema constraints', 'database index',
    'seeding', 'exporting', 'conditional updates', 'viewing data',
    'relational data', 'aggregating', 'normalization', 'jdbc', 'jpa',
    'pathing', 'css', 'git team', 'synching', 'day by day',
    'what are we learning', 'welcome', 'join the discord',
    'demonstration', 'live lecture', 'recap', 'getrange',
    'control flow', 'arrays', 'defining a class',
]

DISCUSSION_KEYWORDS = ['discussion']


def classify_item(title, resource_type, href, module_title=''):
    """Classify a course item into a content type."""
    title_lower = title.lower().strip()
    module_lower = module_title.lower().strip()

    # Quiz type from resource
    if 'imsqti' in resource_type or 'assessment' in resource_type:
        return 'quiz'

    # Web link type
    if 'imswl' in resource_type:
        return 'external'

    # Check title keywords
    if any(kw in title_lower for kw in QUIZ_KEYWORDS):
        return 'quiz'

    # Check for assignments (HTML files with assignment_settings.xml)
    if href and '/assignment_settings.xml' not in href:
        pass

    # Heuristic: if it's an HTML file in a resource dir with assignment_settings
    resource_dir = os.path.dirname(href) if href else ''
    if resource_dir:
        settings_path = os.path.join(BASE_DIR, resource_dir, 'assignment_settings.xml')
        if os.path.exists(settings_path):
            return 'assignment'

    # Keyword-based classification
    for kw in ASSIGNMENT_KEYWORDS:
        if kw in title_lower:
            return 'assignment'

    for kw in PAGE_KEYWORDS:
        if kw in title_lower:
            return 'page'

    # Default: page for discussion topics (imsdt_xmlv1p1)
    if 'imsdt' in resource_type:
        return 'page'

    return 'page'


# ── Generate Markdown files ─────────────────────────────────────────────

def generate_markdown(content_type, title, description_md, links):
    """Generate a complete Markdown file."""
    lines = []
    lines.append('---')
    lines.append(f'type: {content_type}')
    lines.append(f'title: "{title}"')
    lines.append('source: "canvas-import"')
    lines.append('---')
    lines.append('')
    lines.append(f'# {title}')
    lines.append('')
    lines.append('## Description')
    lines.append('')
    if description_md:
        lines.append(description_md)
    else:
        lines.append('*No description provided.*')
    lines.append('')

    if links:
        lines.append('## Links')
        lines.append('')
        seen_urls = set()
        for label, url in links:
            if url in seen_urls:
                continue
            seen_urls.add(url)
            # Improve generic "here" labels
            if label.lower() in ('here', 'link'):
                if 'github.com' in url:
                    label = f'{title} - GitHub Repository'
                elif 'curriculeon.github.io' in url:
                    label = f'{title} - Course Content'
                elif 'discord' in url:
                    label = f'{title} - Discord'
                elif 'docs.google.com' in url:
                    label = f'{title} - Google Doc'
                else:
                    label = title
            lines.append(f'* [{label}]({url})')
        lines.append('')

    return '\n'.join(lines)


def process_resource(item_title, identifierref, resources, module_title=''):
    """Process a single resource, return (content_type, title, markdown_content)."""
    if identifierref not in resources:
        return None

    res = resources[identifierref]
    res_type = res['type']
    res_href = res['href']

    # ── Quiz (QTI assessment) ──
    if 'imsqti' in res_type or 'assessment' in res_type:
        quiz_dir = os.path.join(BASE_DIR, identifierref)
        quiz_title, quiz_desc = read_quiz_meta(quiz_dir)
        title = quiz_title or item_title
        desc_md, links = html_to_markdown(quiz_desc)
        extra_links = extract_links_from_html(quiz_desc)
        all_links = links + [l for l in extra_links if l not in links]
        return 'quiz', title, generate_markdown('quiz', title, desc_md, all_links)

    # ── WebLink ──
    if 'imswl' in res_type:
        wl_path = os.path.join(BASE_DIR, f'{identifierref}.xml')
        wl_title, wl_url = read_weblink(wl_path)
        title = wl_title or item_title
        links = [(title, wl_url)] if wl_url else []
        desc = f'External link: [{title}]({wl_url})' if wl_url else '*No URL provided.*'
        return 'external', title, generate_markdown('external', title, desc, links)

    # ── Discussion Topic (imsdt_xmlv1p1) - XML with <topic> ──
    if 'imsdt' in res_type:
        xml_path = os.path.join(BASE_DIR, f'{identifierref}.xml')
        if os.path.exists(xml_path):
            topic_title, topic_html = read_xml_topic(xml_path)
            title = topic_title or item_title
            desc_md, links = html_to_markdown(topic_html)
            extra_links = extract_links_from_html(topic_html)
            all_links = links + [l for l in extra_links if l not in links]
            content_type = classify_item(title, res_type, '', module_title)
            return content_type, title, generate_markdown(content_type, title, desc_md, all_links)

    # ── Assignment / learning-application-resource with HTML ──
    if res_href and res_href.endswith('.html'):
        html_path = os.path.join(BASE_DIR, res_href)
        if os.path.exists(html_path):
            html_title, html_body = read_html_assignment(html_path)
            title = html_title or item_title
            desc_md, links = html_to_markdown(html_body)
            extra_links = extract_links_from_html(html_body)
            all_links = links + [l for l in extra_links if l not in links]
            content_type = classify_item(title, res_type, res_href, module_title)
            return content_type, title, generate_markdown(content_type, title, desc_md, all_links)

    # ── Fallback: try reading the XML directly ──
    xml_path = os.path.join(BASE_DIR, f'{identifierref}.xml')
    if os.path.exists(xml_path):
        topic_title, topic_html = read_xml_topic(xml_path)
        title = topic_title or item_title
        desc_md, links = html_to_markdown(topic_html)
        extra_links = extract_links_from_html(topic_html)
        all_links = links + [l for l in extra_links if l not in links]
        content_type = classify_item(title, res_type, '', module_title)
        return content_type, title, generate_markdown(content_type, title, desc_md, all_links)

    return None


def main():
    modules, resources = parse_manifest()

    # Track used slugs for deduplication
    used_slugs = {}  # (type, slug) -> count
    created_files = []

    # Create output directories
    for d in ['assignments', 'pages', 'quizzes', 'external', 'projects', 'discussions']:
        os.makedirs(os.path.join(OUTPUT_DIR, d), exist_ok=True)

    # Create module index
    module_index_lines = ['---', 'type: page', 'title: "Course Module Index"', 'source: "canvas-import"', '---', '', '# Public Course - Full Stack Java Microservice', '', '## Module Index', '']

    for i, module in enumerate(modules, 1):
        module_index_lines.append(f'### Module {i}: {module["title"]}')
        module_index_lines.append('')

        for item in module['items']:
            title = item['title']
            identifierref = item.get('identifierref', '')

            if item.get('type') == 'subheader' or not identifierref:
                module_index_lines.append(f'**{title}** *(section header)*')
                module_index_lines.append('')
                continue

            result = process_resource(title, identifierref, resources, module['title'])
            if result is None:
                module_index_lines.append(f'- {title} *(resource not found)*')
                module_index_lines.append('')
                continue

            content_type, resolved_title, markdown_content = result

            # Generate slug
            slug = slugify(resolved_title)
            if not slug:
                slug = slugify(title)
            if not slug:
                slug = 'untitled'

            # Dedup
            slug_key = (content_type, slug)
            if slug_key in used_slugs:
                used_slugs[slug_key] += 1
                slug = f'{slug}-{used_slugs[slug_key]}'
            else:
                used_slugs[slug_key] = 1

            # Map content type to directory
            type_dir_map = {
                'assignment': 'assignments',
                'page': 'pages',
                'quiz': 'quizzes',
                'external': 'external',
                'project': 'projects',
                'discussion': 'discussions',
            }
            dir_name = type_dir_map.get(content_type, 'pages')
            filepath = os.path.join(OUTPUT_DIR, dir_name, f'{slug}.md')

            # Don't overwrite duplicate exact file
            if not os.path.exists(filepath):
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(markdown_content)
                created_files.append(filepath)

            # Add to index
            rel_path = f'{dir_name}/{slug}.md'
            module_index_lines.append(f'- [{resolved_title}]({rel_path})')

        module_index_lines.append('')

    # Write module index
    index_path = os.path.join(OUTPUT_DIR, 'index.md')
    with open(index_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(module_index_lines))
    created_files.append(index_path)

    # Print directory tree
    print("=" * 60)
    print("CONVERSION COMPLETE")
    print("=" * 60)
    print(f"\nTotal files created: {len(created_files)}")
    print(f"\nDirectory tree:")
    print("content/")
    for root_dir, dirs, files in os.walk(OUTPUT_DIR):
        level = root_dir.replace(OUTPUT_DIR, '').count(os.sep)
        indent = '  ' * (level + 1)
        basename = os.path.basename(root_dir)
        if root_dir != OUTPUT_DIR:
            print(f'{indent}{basename}/')
        subindent = '  ' * (level + 2)
        for file in sorted(files):
            print(f'{subindent}{file}')


if __name__ == '__main__':
    main()
