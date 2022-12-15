curl https://api.openai.com/v1/completions \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $tokenValue" \
     -d '{
           "model": "text-davinci-003",
           "prompt": "Explain quantum computing in simple terms.",
           "temperature": 0.5,
           "max_tokens": 2048,
           "top_p": 1,
           "frequency_penalty": 0,
           "presence_penalty": 0
         }'