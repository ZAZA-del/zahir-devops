import json
import urllib.request
import urllib.error

BACKEND_URL = "http://a7d1837a5e5b64a2a8b1af2c8061f58c-1613418956.us-east-1.elb.amazonaws.com"

def handler(event, context):
    try:
        with urllib.request.urlopen(f"{BACKEND_URL}/hello", timeout=5) as resp:
            message = resp.read().decode()
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({
                "source": "AWS Lambda (serverless)",
                "backend_response": message,
                "message": f"Lambda → Spring Boot: {message}"
            })
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(e)})
        }
