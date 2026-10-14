"""Independent, deterministic HMAC/HKDF oracle for the Rust and Dart tests.
Run from any directory with Python 3. Never uses real pairing credentials.
"""
import base64
import hashlib
import hmac
import json
from pathlib import Path

def b64(value):
    return base64.urlsafe_b64encode(value).decode().rstrip("=")

def transcript(label, *fields):
    values = [label.encode(), *fields]
    return b"".join(len(v).to_bytes(4, "big") + v for v in values)

def tag(key, message):
    return hmac.new(key, message, hashlib.sha256).digest()

key = bytes(range(32))
client_nonce = bytes(range(32, 64))
server_nonce = bytes(range(64, 96))
session = bytes(range(96, 112))
hello = dict(version=2, server_id="computer-test", device_id="phone-test",
             device_name="Phone café", invite_id="invite-test", client_nonce=b64(client_nonce))
hello_bytes = transcript("laze-v2/client-hello", hello["server_id"].encode(),
                         hello["device_id"].encode(), hello["device_name"].encode(),
                         hello["invite_id"].encode(), client_nonce)
hello["proof"] = b64(tag(key, hello_bytes))
challenge = dict(version=2, session_id=b64(session), server_nonce=b64(server_nonce),
                 server_os="windows", udp_port=7876)
challenge_bytes = transcript("laze-v2/server-challenge", hello_bytes, server_nonce,
                             session, b"windows", (7876).to_bytes(2, "big"))
challenge["proof"] = b64(tag(key, challenge_bytes))
finish = dict(proof=b64(tag(key, transcript("laze-v2/client-finish", challenge_bytes))))
prk = tag(client_nonce + server_nonce, key)
keys = {}
for label in ("client-tcp", "client-udp", "server-tcp"):
    info = transcript("laze-v2/session-key", b"computer-test", b"phone-test",
                      session, label.encode())
    keys[label] = tag(prk, info + b"\x01")

def record(label, sequence, payload):
    body = session + sequence.to_bytes(8, "big") + payload
    return b64(body + tag(keys[label], body))

data = dict(secret=b64(key), hello=hello, challenge=challenge, finish=finish,
            hello_bytes=b64(hello_bytes), challenge_bytes=b64(challenge_bytes),
            keys={k:b64(v) for k,v in keys.items()},
            tcp_record=record("client-tcp", 0, bytes([4, 0])),
            udp_record=record("client-udp", 0, bytes([3, 1, 255])),
            ready_record=record("server-tcp", 0, bytes([253])))
Path(__file__).with_name("auth-v2-vectors.json").write_text(
    json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
