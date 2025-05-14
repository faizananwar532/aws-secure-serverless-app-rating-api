import hmac
import hashlib
import base64

def get_secret_hash(username, client_id, client_secret):
    message = username + client_id
    dig = hmac.new(
        str(client_secret).encode('utf-8'),
        msg=message.encode('utf-8'),
        digestmod=hashlib.sha256
    ).digest()
    return base64.b64encode(dig).decode()

# Example usage:
print(get_secret_hash('faizan.anwar', '70j4oenqlisu7vo9f7a9f963ou', '53uq2i541ue9se5d0nliu3hhn7ffo15nmpk8ai4ov477a3lmqs6'))