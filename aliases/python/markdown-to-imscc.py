#!/usr/bin/env python3
"""
Convert structured Markdown directory back to IMS Common Cartridge (.imscc).

This is the reverse of imscc-to-markdown.py.  It reads a directory of
markdown files produced by imscc2md and generates a valid IMS CC 1.1
package that can be imported into Canvas, Moodle, Schoology, or any
other SCORM/IMS-CC-compliant LMS.

Input directory structure:
    content/
        index.md            ← module index (parsed for hierarchy)
        assignments/*.md
        pages/*.md
        quizzes/*.md
        external/*.md
        discussions/*.md
        projects/*.md

Output:
    <name>.imscc            ← ZIP file with IMS CC structure

Usage:
    python markdown-to-imscc.py <input_dir> <output_imscc>
"""

import os
import re
import sys
import uuid
import html
import zipfile
from datetime import datetime


# ── Helpers ─────────────────────────────────────────────────────────────

def gen_id():
    """Generate a Canvas-style hex identifier."""
    return 'g' + uuid.uuid4().hex[:31]


def escape_xml(text):
    """Escape text for XML attribute/content use."""
    return html.escape(text, quote=True)


def html_escape_content(text):
    """Escape text for use inside XML CDATA-like text elements."""
    return html.escape(text, quote=False)


# ── Parse frontmatter ───────────────────────────────────────────────────

def parse_frontmatter(md_text):
    """Parse YAML frontmatter from markdown, return (metadata_dict, body)."""
    meta = {}
    body = md_text
    if md_text.startswith('---'):
        parts = md_text.split('---', 2)
        if len(parts) >= 3:
            fm = parts[1].strip()
            body = parts[2].strip()
            for line in fm.split('\n'):
                line = line.strip()
                if ':' in line:
                    key, val = line.split(':', 1)
                    key = key.strip()
                    val = val.strip().strip('"').strip("'")
                    meta[key] = val
    return meta, body


# ── Parse markdown body ─────────────────────────────────────────────────

def extract_description(body):
    """Extract the description section text from markdown body."""
    desc = ''
    in_desc = False
    lines = body.split('\n')
    for line in lines:
        if line.strip().startswith('## Description'):
            in_desc = True
            continue
        if in_desc and line.strip().startswith('## '):
            break
        if in_desc:
            desc += line + '\n'
    return desc.strip()


def extract_links(body):
    """Extract links from the ## Links section, return list of (label, url)."""
    links = []
    in_links = False
    lines = body.split('\n')
    for line in lines:
        if line.strip().startswith('## Links'):
            in_links = True
            continue
        if in_links and line.strip().startswith('## '):
            break
        if in_links:
            match = re.search(r'\[([^\]]+)\]\(([^)]+)\)', line)
            if match:
                links.append((match.group(1), match.group(2)))
    return links


def markdown_to_html(md_body):
    """Convert simple markdown body to HTML for embedding in IMSCC XML."""
    # Strip out frontmatter sections we handle separately
    lines = md_body.split('\n')
    html_parts = []

    for line in lines:
        stripped = line.strip()
        # Skip section headers we handle structurally
        if stripped.startswith('# ') and not stripped.startswith('## '):
            continue
        if stripped == '## Description' or stripped == '## Links':
            continue
        if stripped == '*No description provided.*':
            continue

        # Bold
        processed = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', stripped)
        # Italic
        processed = re.sub(r'\*(.+?)\*', r'<em>\1</em>', processed)
        # Links
        processed = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', processed)
        # Images
        processed = re.sub(r'!\[([^\]]*)\]\(([^)]+)\)', r'<img src="\2" alt="\1"/>', processed)
        # Headings
        if processed.startswith('### '):
            processed = f'<h3>{processed[4:]}</h3>'
        elif processed.startswith('## '):
            processed = f'<h2>{processed[3:]}</h2>'
        # List items
        elif processed.startswith('- ') or processed.startswith('* '):
            processed = f'<li>{processed[2:]}</li>'
        elif processed:
            processed = f'<p>{processed}</p>'

        if processed:
            html_parts.append(processed)

    return '\n'.join(html_parts)


# ── Parse index.md for module hierarchy ─────────────────────────────────

def parse_index(index_path):
    """Parse index.md to recover module hierarchy.

    Returns list of modules:
    [
        {
            'title': 'Module Title',
            'items': [
                {'title': 'Item Title', 'rel_path': 'pages/foo.md'},
                ...
            ]
        },
        ...
    ]
    """
    with open(index_path, 'r', encoding='utf-8') as f:
        content = f.read()

    modules = []
    current_module = None

    for line in content.split('\n'):
        line = line.strip()

        # Module header: ### Module N: Title
        m = re.match(r'^###\s+Module\s+\d+:\s+(.+)$', line)
        if m:
            if current_module:
                modules.append(current_module)
            current_module = {'title': m.group(1).strip(), 'items': []}
            continue

        # Section header (bold text with *(section header)*)
        m = re.match(r'^\*\*(.+?)\*\*\s*\*\(section header\)\*', line)
        if m and current_module is not None:
            current_module['items'].append({
                'title': m.group(1).strip(),
                'rel_path': None,
                'type': 'subheader',
            })
            continue

        # Item link: - [Title](path/to/file.md)
        m = re.match(r'^-\s+\[(.+?)\]\((.+?)\)', line)
        if m and current_module is not None:
            current_module['items'].append({
                'title': m.group(1).strip(),
                'rel_path': m.group(2).strip(),
            })
            continue

        # Item without link: - Title *(resource not found)*
        m = re.match(r'^-\s+(.+?)\s*\*\(resource not found\)\*', line)
        if m and current_module is not None:
            current_module['items'].append({
                'title': m.group(1).strip(),
                'rel_path': None,
                'type': 'missing',
            })
            continue

    if current_module:
        modules.append(current_module)

    return modules


# ── Generate IMS CC XML files ───────────────────────────────────────────

def make_topic_xml(title, html_body):
    """Generate an imsdt topic XML string."""
    escaped_html = html_escape_content(html_body)
    return (
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<topic xmlns="http://www.imsglobal.org/xsd/imsccv1p1/imsdt_v1p1" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:schemaLocation="http://www.imsglobal.org/xsd/imsccv1p1/imsdt_v1p1 '
        ' http://www.imsglobal.org/profile/cc/ccv1p1/ccv1p1_imsdt_v1p1.xsd">'
        f'<title>{escape_xml(title)}</title>'
        f'<text texttype="text/html">{escaped_html}</text>'
        '</topic>'
    )


def make_topic_meta_xml(identifier, topic_id, title):
    """Generate a Canvas topicMeta XML string."""
    return (
        '<?xml version="1.0" encoding="UTF-8"?>'
        f'<topicMeta identifier="{identifier}" '
        'xmlns="http://canvas.instructure.com/xsd/cccv1p0" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:schemaLocation="http://canvas.instructure.com/xsd/cccv1p0 '
        'https://canvas.instructure.com/xsd/cccv1p0.xsd">'
        f'<topic_id>{topic_id}</topic_id>'
        f'<title>{escape_xml(title)}</title>'
        '<position/>'
        '<type>topic</type>'
        '<discussion_type>side_comment</discussion_type>'
        '<has_group_category>false</has_group_category>'
        '<workflow_state>active</workflow_state>'
        '<module_locked>false</module_locked>'
        '<allow_rating>false</allow_rating>'
        '<only_graders_can_rate>false</only_graders_can_rate>'
        '<sort_by_rating>false</sort_by_rating>'
        '<todo_date/>'
        '</topicMeta>'
    )


def make_assignment_html(title):
    """Generate an assignment HTML file."""
    return (
        '<html>\n<head>\n'
        '<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>\n'
        f'<title>Assignment: {html.escape(title)}</title>\n'
        '</head>\n<body>\n\n</body>\n</html>\n'
    )


def make_assignment_settings_xml(identifier, title, position):
    """Generate a Canvas assignment_settings.xml."""
    return (
        '<?xml version="1.0" encoding="UTF-8"?>'
        f'<assignment identifier="{identifier}" '
        'xmlns="http://canvas.instructure.com/xsd/cccv1p0" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:schemaLocation="http://canvas.instructure.com/xsd/cccv1p0 '
        'https://canvas.instructure.com/xsd/cccv1p0.xsd">'
        f'<title>{escape_xml(title)}</title>'
        '<due_at/><lock_at/><unlock_at/>'
        '<module_locked>false</module_locked>'
        '<workflow_state>unpublished</workflow_state>'
        '<assignment_overrides></assignment_overrides>'
        '<allowed_extensions></allowed_extensions>'
        '<has_group_category>false</has_group_category>'
        '<grading_type>points</grading_type>'
        '<all_day>false</all_day>'
        '<submission_types>none</submission_types>'
        f'<position>{position}</position>'
        '<turnitin_enabled>false</turnitin_enabled>'
        '<vericite_enabled>false</vericite_enabled>'
        '<peer_review_count>0</peer_review_count>'
        '<peer_reviews>false</peer_reviews>'
        '<automatic_peer_reviews>false</automatic_peer_reviews>'
        '<anonymous_peer_reviews>false</anonymous_peer_reviews>'
        '<grade_group_students_individually>false</grade_group_students_individually>'
        '<freeze_on_copy>false</freeze_on_copy>'
        '<omit_from_final_grade>false</omit_from_final_grade>'
        '<intra_group_peer_reviews>false</intra_group_peer_reviews>'
        '<only_visible_to_overrides>false</only_visible_to_overrides>'
        '<post_to_sis>false</post_to_sis>'
        '<moderated_grading>false</moderated_grading>'
        '<grader_count>0</grader_count>'
        '<grader_comments_visible_to_graders>true</grader_comments_visible_to_graders>'
        '<anonymous_grading>false</anonymous_grading>'
        '<graders_anonymous_to_graders>false</graders_anonymous_to_graders>'
        '<grader_names_visible_to_final_grader>true</grader_names_visible_to_final_grader>'
        '<anonymous_instructor_annotations>false</anonymous_instructor_annotations>'
        '<post_policy><post_manually>false</post_manually></post_policy>'
        '</assignment>'
    )


def make_quiz_meta_xml(identifier, title, position):
    """Generate a Canvas quiz assessment_meta.xml."""
    assgn_id = gen_id()
    return (
        '<?xml version="1.0" encoding="UTF-8"?>'
        f'<quiz identifier="{identifier}" '
        'xmlns="http://canvas.instructure.com/xsd/cccv1p0" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:schemaLocation="http://canvas.instructure.com/xsd/cccv1p0 '
        'https://canvas.instructure.com/xsd/cccv1p0.xsd">'
        f'<title>{escape_xml(title)}</title>'
        '<description></description>'
        '<shuffle_answers>false</shuffle_answers>'
        '<scoring_policy>keep_highest</scoring_policy>'
        '<hide_results></hide_results>'
        '<quiz_type>assignment</quiz_type>'
        '<points_possible/>'
        '<require_lockdown_browser>false</require_lockdown_browser>'
        '<require_lockdown_browser_for_results>false</require_lockdown_browser_for_results>'
        '<require_lockdown_browser_monitor>false</require_lockdown_browser_monitor>'
        '<lockdown_browser_monitor_data/>'
        '<show_correct_answers>true</show_correct_answers>'
        '<anonymous_submissions>false</anonymous_submissions>'
        '<could_be_locked>true</could_be_locked>'
        '<disable_timer_autosubmission>false</disable_timer_autosubmission>'
        '<allowed_attempts>1</allowed_attempts>'
        '<one_question_at_a_time>false</one_question_at_a_time>'
        '<cant_go_back>false</cant_go_back>'
        '<available>false</available>'
        '<one_time_results>false</one_time_results>'
        '<show_correct_answers_last_attempt>false</show_correct_answers_last_attempt>'
        '<only_visible_to_overrides>false</only_visible_to_overrides>'
        '<module_locked>false</module_locked>'
        f'<assignment identifier="{assgn_id}">'
        f'<title>{escape_xml(title)}</title>'
        '<due_at/><lock_at/><unlock_at/>'
        '<module_locked>false</module_locked>'
        '<workflow_state>unpublished</workflow_state>'
        '<assignment_overrides></assignment_overrides>'
        f'<quiz_identifierref>{identifier}</quiz_identifierref>'
        '<allowed_extensions></allowed_extensions>'
        '<has_group_category>false</has_group_category>'
        '<grading_type>points</grading_type>'
        '<all_day>false</all_day>'
        '<submission_types>online_quiz</submission_types>'
        f'<position>{position}</position>'
        '<turnitin_enabled>false</turnitin_enabled>'
        '<vericite_enabled>false</vericite_enabled>'
        '<peer_review_count>0</peer_review_count>'
        '<peer_reviews>false</peer_reviews>'
        '<automatic_peer_reviews>false</automatic_peer_reviews>'
        '<anonymous_peer_reviews>false</anonymous_peer_reviews>'
        '<grade_group_students_individually>false</grade_group_students_individually>'
        '<freeze_on_copy>false</freeze_on_copy>'
        '<omit_from_final_grade>false</omit_from_final_grade>'
        '<intra_group_peer_reviews>false</intra_group_peer_reviews>'
        '<only_visible_to_overrides>false</only_visible_to_overrides>'
        '<post_to_sis>false</post_to_sis>'
        '<moderated_grading>false</moderated_grading>'
        '<grader_count>0</grader_count>'
        '<grader_comments_visible_to_graders>true</grader_comments_visible_to_graders>'
        '<anonymous_grading>false</anonymous_grading>'
        '<graders_anonymous_to_graders>false</graders_anonymous_to_graders>'
        '<grader_names_visible_to_final_grader>true</grader_names_visible_to_final_grader>'
        '<anonymous_instructor_annotations>false</anonymous_instructor_annotations>'
        '<post_policy><post_manually>false</post_manually></post_policy>'
        '</assignment>'
        '<assignment_overrides></assignment_overrides>'
        '</quiz>'
    )


def make_weblink_xml(title, url):
    """Generate a webLink XML for external links."""
    return (
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<webLink xmlns="http://www.imsglobal.org/xsd/imsccv1p1/imswl_v1p1" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:schemaLocation="http://www.imsglobal.org/xsd/imsccv1p1/imswl_v1p1 '
        'http://www.imsglobal.org/profile/cc/ccv1p1/ccv1p1_imswl_v1p1.xsd">'
        f'<title>{escape_xml(title)}</title>'
        f'<url href="{escape_xml(url)}"/>'
        '</webLink>'
    )


def make_course_settings():
    """Generate minimal course_settings files."""
    settings = (
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<course xmlns="http://canvas.instructure.com/xsd/cccv1p0" '
        'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
        'xsi:schemaLocation="http://canvas.instructure.com/xsd/cccv1p0 '
        'https://canvas.instructure.com/xsd/cccv1p0.xsd" '
        'identifier="course_settings">'
        '<title>Imported Course</title>'
        '<default_view>modules</default_view>'
        '</course>'
    )
    export_txt = f'Course exported at {datetime.now().isoformat()}\n'
    return settings, export_txt


# ── Build the package ───────────────────────────────────────────────────

def build_imscc(input_dir, output_path):
    """Build an .imscc ZIP from a converted-to-markdown directory."""

    index_path = os.path.join(input_dir, 'index.md')
    if not os.path.isfile(index_path):
        print(f"ERROR: index.md not found in {input_dir}")
        sys.exit(1)

    modules = parse_index(index_path)
    if not modules:
        print(f"ERROR: No modules parsed from {index_path}")
        sys.exit(1)

    print(f"Parsed {len(modules)} modules from index.md")

    # Collect all files to write into the ZIP
    # Each entry: (archive_path, content_bytes)
    zip_entries = []

    # Track resources for manifest
    resources = []          # list of resource XML fragments
    org_items = []          # list of organization item XML fragments
    assignment_group_id = gen_id()

    global_position = 0

    for mod_idx, module in enumerate(modules, 1):
        module_id = gen_id()
        module_items_xml = []

        for item in module['items']:
            title = item['title']
            rel_path = item.get('rel_path')
            item_type = item.get('type', '')

            # Subheaders — no resource, just a title item
            if item_type == 'subheader':
                sub_id = gen_id()
                module_items_xml.append(
                    f'<item identifier="{sub_id}">'
                    f'<title>{escape_xml(title)}</title>'
                    f'</item>'
                )
                continue

            # Missing resources — skip
            if item_type == 'missing' or not rel_path:
                continue

            # Read the markdown file
            md_path = os.path.join(input_dir, rel_path)
            if not os.path.isfile(md_path):
                print(f"  WARN: File not found: {rel_path}, skipping")
                continue

            with open(md_path, 'r', encoding='utf-8') as f:
                md_text = f.read()

            meta, body = parse_frontmatter(md_text)
            content_type = meta.get('type', 'page')
            resolved_title = meta.get('title', title)
            description = extract_description(body)
            links = extract_links(body)

            global_position += 1

            # Build HTML body from description + links
            html_parts = []
            if description and description != '*No description provided.*':
                html_parts.append(f'<p>{html_escape_content(description)}</p>')
            for label, url in links:
                html_parts.append(
                    f'<p><a href="{html.escape(url)}">{html.escape(label)}</a></p>'
                )
            html_body = '\n'.join(html_parts) if html_parts else ''

            # ── Generate resources based on type ──

            if content_type == 'assignment':
                res_id = gen_id()
                item_id = gen_id()

                # Assignment HTML file
                assgn_html = make_assignment_html(resolved_title)
                assgn_dir = res_id
                zip_entries.append((f'{assgn_dir}/{res_id}.html', assgn_html.encode('utf-8')))

                # assignment_settings.xml
                settings_xml = make_assignment_settings_xml(res_id, resolved_title, global_position)
                zip_entries.append((f'{assgn_dir}/assignment_settings.xml', settings_xml.encode('utf-8')))

                resources.append(
                    f'<resource identifier="{res_id}" '
                    f'type="associatedcontent/imscc_xmlv1p1/learning-application-resource" '
                    f'href="{assgn_dir}/{res_id}.html">'
                    f'<file href="{assgn_dir}/{res_id}.html"/>'
                    f'<file href="{assgn_dir}/assignment_settings.xml"/>'
                    f'</resource>'
                )

                module_items_xml.append(
                    f'<item identifier="{item_id}" identifierref="{res_id}">'
                    f'<title>{escape_xml(resolved_title)}</title>'
                    f'</item>'
                )

            elif content_type == 'quiz':
                res_id = gen_id()
                item_id = gen_id()

                # Quiz directory with assessment_meta.xml
                quiz_meta = make_quiz_meta_xml(res_id, resolved_title, global_position)
                zip_entries.append((f'{res_id}/assessment_meta.xml', quiz_meta.encode('utf-8')))

                # Minimal QTI assessment XML
                qti_xml = (
                    '<?xml version="1.0" encoding="UTF-8"?>'
                    '<questestinterop xmlns="http://www.imsglobal.org/xsd/ims_qtiasiv1p2" '
                    'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" '
                    'xsi:schemaLocation="http://www.imsglobal.org/xsd/ims_qtiasiv1p2 '
                    'http://www.imsglobal.org/xsd/ims_qtiasiv1p2p1.xsd">'
                    f'<assessment ident="{res_id}" title="{escape_xml(resolved_title)}">'
                    '<section ident="root_section"/>'
                    '</assessment>'
                    '</questestinterop>'
                )
                zip_entries.append((f'{res_id}/assessment_qti.xml', qti_xml.encode('utf-8')))

                resources.append(
                    f'<resource identifier="{res_id}" '
                    f'type="imsqti_xmlv1p2/imscc_xmlv1p1/assessment">'
                    f'<file href="{res_id}/assessment_meta.xml"/>'
                    f'<file href="{res_id}/assessment_qti.xml"/>'
                    f'</resource>'
                )

                module_items_xml.append(
                    f'<item identifier="{item_id}" identifierref="{res_id}">'
                    f'<title>{escape_xml(resolved_title)}</title>'
                    f'</item>'
                )

            elif content_type == 'external':
                # External weblink
                res_id = gen_id()
                item_id = gen_id()

                url = links[0][1] if links else ''
                wl_xml = make_weblink_xml(resolved_title, url)
                zip_entries.append((f'{res_id}.xml', wl_xml.encode('utf-8')))

                resources.append(
                    f'<resource identifier="{res_id}" '
                    f'type="imswl_xmlv1p1">'
                    f'<file href="{res_id}.xml"/>'
                    f'</resource>'
                )

                module_items_xml.append(
                    f'<item identifier="{item_id}" identifierref="{res_id}">'
                    f'<title>{escape_xml(resolved_title)}</title>'
                    f'</item>'
                )

            else:
                # Default: page (imsdt topic XML)
                # Each page gets two resources:
                #   1. imsdt topic XML (content)
                #   2. associatedcontent topicMeta XML (Canvas metadata)
                topic_id = gen_id()
                meta_id = gen_id()
                item_id = gen_id()

                topic_xml = make_topic_xml(resolved_title, html_body)
                zip_entries.append((f'{topic_id}.xml', topic_xml.encode('utf-8')))

                meta_xml = make_topic_meta_xml(meta_id, topic_id, resolved_title)
                zip_entries.append((f'{meta_id}.xml', meta_xml.encode('utf-8')))

                resources.append(
                    f'<resource identifier="{topic_id}" '
                    f'type="imsdt_xmlv1p1">'
                    f'<file href="{topic_id}.xml"/>'
                    f'<dependency identifierref="{meta_id}"/>'
                    f'</resource>'
                )
                resources.append(
                    f'<resource identifier="{meta_id}" '
                    f'type="associatedcontent/imscc_xmlv1p1/learning-application-resource" '
                    f'href="{meta_id}.xml">'
                    f'<file href="{meta_id}.xml"/>'
                    f'</resource>'
                )

                module_items_xml.append(
                    f'<item identifier="{item_id}" identifierref="{topic_id}">'
                    f'<title>{escape_xml(resolved_title)}</title>'
                    f'</item>'
                )

        # Build module organization item
        items_joined = '\n'.join(module_items_xml)
        org_items.append(
            f'<item identifier="{module_id}">'
            f'<title>{escape_xml(module["title"])}</title>'
            f'{items_joined}'
            f'</item>'
        )

    # ── Course settings ──
    course_settings_id = gen_id()
    settings_xml, export_txt = make_course_settings()
    zip_entries.append(('course_settings/course_settings.xml', settings_xml.encode('utf-8')))
    zip_entries.append(('course_settings/canvas_export.txt', export_txt.encode('utf-8')))

    resources.append(
        f'<resource identifier="{course_settings_id}" '
        f'type="associatedcontent/imscc_xmlv1p1/learning-application-resource" '
        f'href="course_settings/canvas_export.txt">'
        f'<file href="course_settings/canvas_export.txt"/>'
        f'<file href="course_settings/course_settings.xml"/>'
        f'</resource>'
    )

    # ── Build imsmanifest.xml ──
    org_items_joined = '\n'.join(org_items)
    resources_joined = '\n'.join(resources)
    today = datetime.now().strftime('%Y-%m-%d')

    manifest = f'''<?xml version="1.0" encoding="UTF-8"?>
<manifest identifier="{gen_id()}"
  xmlns="http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1"
  xmlns:lom="http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource"
  xmlns:lomimscc="http://ltsc.ieee.org/xsd/imsccv1p1/LOM/manifest"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://www.imsglobal.org/xsd/imsccv1p1/imscp_v1p1
    http://www.imsglobal.org/profile/cc/ccv1p1/ccv1p1_imscp_v1p1_v1p0.xsd
    http://ltsc.ieee.org/xsd/imsccv1p1/LOM/resource
    http://www.imsglobal.org/profile/cc/ccv1p1/LOM/ccv1p1_lomresource_v1p0.xsd
    http://ltsc.ieee.org/xsd/imsccv1p1/LOM/manifest
    http://www.imsglobal.org/profile/cc/ccv1p1/LOM/ccv1p1_lommanifest_v1p0.xsd">
  <metadata>
    <schema>IMS Common Cartridge</schema>
    <schemaversion>1.1.0</schemaversion>
    <lomimscc:lom>
      <lomimscc:general>
        <lomimscc:title>
          <lomimscc:string language="en">Exported Course</lomimscc:string>
        </lomimscc:title>
      </lomimscc:general>
      <lomimscc:lifeCycle>
        <lomimscc:contribute>
          <lomimscc:date>
            <lomimscc:dateTime>{today}</lomimscc:dateTime>
          </lomimscc:date>
        </lomimscc:contribute>
      </lomimscc:lifeCycle>
      <lomimscc:rights>
        <lomimscc:copyrightAndOtherRestrictions>
          <lomimscc:value>yes</lomimscc:value>
        </lomimscc:copyrightAndOtherRestrictions>
        <lomimscc:description>
          <lomimscc:string>Private (Copyrighted) - http://en.wikipedia.org/wiki/Copyright</lomimscc:string>
        </lomimscc:description>
      </lomimscc:rights>
    </lomimscc:lom>
  </metadata>
  <organizations>
    <organization identifier="org_1" structure="rooted-hierarchy">
      <item identifier="LearningModules">
{org_items_joined}
      </item>
    </organization>
  </organizations>
  <resources>
{resources_joined}
  </resources>
</manifest>'''

    zip_entries.append(('imsmanifest.xml', manifest.encode('utf-8')))

    # ── Write the ZIP (.imscc) ──
    with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zf:
        for arc_path, content in zip_entries:
            zf.writestr(arc_path, content)

    print(f"\nPackage created: {output_path}")
    print(f"  Files in package: {len(zip_entries)}")
    print(f"  Modules: {len(modules)}")
    total_items = sum(len(m['items']) for m in modules)
    print(f"  Total items: {total_items}")


# ── Main ────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python markdown-to-imscc.py <input_dir> <output.imscc>")
        print("  <input_dir>    Path to *_converted-to-markdown/ directory")
        print("  <output.imscc> Path for the output .imscc file")
        sys.exit(1)

    input_dir = sys.argv[1]
    output_path = sys.argv[2]

    if not os.path.isdir(input_dir):
        print(f"ERROR: Input directory not found: {input_dir}")
        sys.exit(1)

    build_imscc(input_dir, output_path)
