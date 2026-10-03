#!/usr/bin/env python3
"""Loopback fixture server for `make ai-loopback` (harness; CLAUDE.md "Python").

usage: ai_loopback.py serve DIR     serve on 127.0.0.1 (ephemeral port, written
                                    to DIR/port) until DIR/stop appears
       ai_loopback.py check DIR KEY_GEMINI KEY_OPENROUTER

It stands in for OpenRouter chat completions and Gemini TTS so the std/net
halves of ai/adapters.ail run with fake keys and no network. Every request is
logged to DIR/requests.ndjson (method, path, the two auth headers, body). The
first chat completion is answered with the "Wait" fixture (bad_output), so the
adapter must retry; later ones get openrouter_ok.json. TTS answers
gemini_tts_ok.json (output tokens set inside the cap). `check` asserts the URLs, headers, bodies and the retry,
and that neither key appears in the lane's stdout/stderr or in DIR/cache.
"""
import http.server
import json
import os
import sys
import threading

FIX = os.path.join(os.path.dirname(__file__), "..", "..", "ai", "fixtures", "responses")
OR_PATH = "/api/v1/chat/completions"
TTS_PATH = "/v1beta/models/gemini-2.5-flash-preview-tts:generateContent"


def fixture(name):
    with open(os.path.join(FIX, name), "rb") as f:
        return f.read()


def serve(d):
    log = open(os.path.join(d, "requests.ndjson"), "a")
    seen = {"or": 0}

    class H(http.server.BaseHTTPRequestHandler):
        def log_message(self, *a):
            pass

        def do_POST(self):
            body = self.rfile.read(int(self.headers.get("Content-Length", 0))).decode()
            log.write(json.dumps({"method": "POST", "path": self.path,
                                  "authorization": self.headers.get("Authorization"),
                                  "x_goog_api_key": self.headers.get("x-goog-api-key"),
                                  "content_type": self.headers.get("Content-Type"), "body": body}) + "\n")
            log.flush()
            if self.path.startswith("/drop/"):
                # AI.9 hardening: the call was sent, no reply comes back (transport error after send).
                self.close_connection = True
                self.connection.shutdown(2)
                return
            if self.path == "/nocontent" + OR_PATH:
                # AI.9: billed (usage reported) but no content: provider_error, still charged.
                out = json.dumps({"id": "gen-billed", "choices": [{"finish_reason": "stop", "message": {"role": "assistant"}}],
                                  "usage": {"prompt_tokens": 312, "completion_tokens": 27}}).encode()
            elif self.path == "/capped" + TTS_PATH:
                # AI.9: the committed fixture as is: 118 output tokens over a cap of 98, bad_output, still charged.
                out = fixture("gemini_tts_ok.json")
            elif self.path == OR_PATH:
                seen["or"] += 1
                out = fixture("openrouter_wait.json" if seen["or"] == 1 else "openrouter_ok.json")
            elif self.path == TTS_PATH:
                # The fixture reports 118 output tokens; a one-segment line's cap is
                # 2 * 24 + 50 = 98, so as committed it is (rightly) cut-off speech.
                # Here it reports 40, inside the cap, so the success path runs too.
                d = json.loads(fixture("gemini_tts_ok.json"))
                d["usageMetadata"]["candidatesTokenCount"] = 40
                out = json.dumps(d).encode()
            else:
                self.send_response(404)
                self.end_headers()
                return
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(out)))
            self.end_headers()
            self.wfile.write(out)

    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), H)
    with open(os.path.join(d, "port.tmp"), "w") as f:
        f.write(str(srv.server_address[1]))
    os.rename(os.path.join(d, "port.tmp"), os.path.join(d, "port"))
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    stop = os.path.join(d, "stop")
    for _ in range(1200):  # at most 60 s
        if os.path.exists(stop):
            break
        threading.Event().wait(0.05)
    srv.shutdown()


def check(d, kg, ko):
    fails = []
    reqs = [json.loads(l) for l in open(os.path.join(d, "requests.ndjson"))]
    ors = [r for r in reqs if r["path"] == OR_PATH]
    tts = [r for r in reqs if r["path"] == TTS_PATH]
    billed = [r for r in reqs if r["path"] in ("/nocontent" + OR_PATH, "/capped" + TTS_PATH)]
    dropped = [r for r in reqs if r["path"] in ("/drop" + OR_PATH, "/drop" + TTS_PATH)]
    if len(ors) != 2:
        fails.append("expected 2 chat completions (one retry after the Wait fixture), got %d" % len(ors))
    for r in ors:
        b = json.loads(r["body"])
        if r["authorization"] != "Bearer " + ko or r["x_goog_api_key"] is not None:
            fails.append("chat completion auth headers wrong")
        if r["content_type"] != "application/json" or b.get("model") != "mistralai/mistral-nemo" \
                or [m["role"] for m in b.get("messages", [])] != ["system", "user"] or b.get("max_tokens") != 172:
            fails.append("chat completion body wrong: %s" % r["body"][:200])
    if len(tts) != 1:
        fails.append("expected 1 TTS call (one segment), got %d" % len(tts))
    for r in tts:
        b = json.loads(r["body"])
        if r["x_goog_api_key"] != kg or r["authorization"] is not None:
            fails.append("TTS auth headers wrong")
        if "Stub line one for medic." not in r["body"] or "generationConfig" not in b:
            fails.append("TTS body wrong: %s" % r["body"][:200])
    lane = open(os.path.join(d, "lane.out")).read()
    if '"req":"1","status":"ok"' not in lane or '"req":"12","status":"ok","kind":"voice"' not in lane:
        fails.append("lane results not ok: %s" % lane[-400:])
    # AI.9: each billed failure is one call with its tokens, a nonzero charge and a usage line.
    want = {"openrouter": "billed openrouter: provider_error, 1 calls, 312+27 tokens, ledger 0 -> ",
            "tts": "billed tts: bad_output, 1 calls, "}
    for k, w in want.items():
        line = next((l for l in lane.splitlines() if l.startswith("billed " + k + ":")), "")
        nano = line.rsplit("-> ", 1)[-1].split(" ")[0] if "-> " in line else ""
        if not line.startswith(w) or not nano.isdigit() or int(nano) <= 0:
            fails.append("billed %s failure not charged: %r" % (k, line))
    # AI.9 hardening: a call sent but never answered is charged at its cap: the
    # OpenRouter text cap is 172 output tokens, the one-segment TTS cap 98.
    want = {"dropped openrouter": "dropped openrouter: provider_error, 1 calls, ", "dropped tts": "dropped tts: provider_error, 1 calls, 6+98 tokens"}
    for k, w in want.items():
        line = next((l for l in lane.splitlines() if l.startswith("billed " + k + ":")), "")
        nano = line.rsplit("-> ", 1)[-1].split(" ")[0] if "-> " in line else ""
        if not line.startswith("billed " + w) or not nano.isdigit() or int(nano) <= 0 or (k == "dropped openrouter" and "+172 tokens" not in line):
            fails.append("%s call not charged: %r" % (k, line))
    res = os.path.join(d, "cache", "inflight.json")
    rv = json.loads(open(res).read()) if os.path.exists(res) else {}
    est = next((l.split(": ")[1].split(" ")[0] for l in lane.splitlines() if l.startswith("reserved 912: ")), "")
    if rv.get("req") != "912" or rv.get("provisional") is not True or rv.get("route") != "gemini" or not est.isdigit() \
            or int(est) <= 0 or round(rv.get("usd", 0) * 1e9) != int(est):
        fails.append("reservation (inflight.json) is not the worst case of 912: %s vs %s" % (rv, est))
    usage = open(os.path.join(d, "cache", "usage.ndjson")).read() if os.path.exists(os.path.join(d, "cache", "usage.ndjson")) else ""
    for req in ("b1", "b12", "d1", "d12"):
        lines = [json.loads(l) for l in usage.splitlines() if json.loads(l).get("req") == req]
        if len(lines) != 1 or lines[0]["calls"] != 1 or not lines[0]["usd"] > 0:
            fails.append("usage.ndjson has no charged line for billed failure %s: %s" % (req, lines))
    if len(billed) != 2:
        fails.append("expected 2 billed-failure calls (/nocontent, /capped), got %d" % len(billed))
    if len(dropped) != 2:
        fails.append("expected 2 dropped calls (/drop chat completion, /drop TTS), got %d" % len(dropped))
    if len(reqs) != len(ors) + len(tts) + len(billed) + len(dropped):
        fails.append("unexpected paths: %s" % sorted({r["path"] for r in reqs}))
    places = [os.path.join(d, "lane.out"), os.path.join(d, "lane.err")]
    for root, _, files in os.walk(os.path.join(d, "cache")):
        places += [os.path.join(root, f) for f in files]
    for p in places:
        data = open(p, "rb").read()
        for k in (kg, ko):
            if k.encode() in data:
                fails.append("key text in %s" % os.path.relpath(p, d))
    for f in fails:
        print("FAIL " + f)
    print("ai-loopback: %d chat completions (Bearer, retry after Wait), %d TTS (x-goog-api-key), %d billed failures and %d dropped calls charged, reservation = worst case; keys absent from stdout, stderr and %d cache files%s"
          % (len(ors), len(tts), len(billed), len(dropped), len(places) - 2, "" if not fails else " -- FAILED"))
    return 1 if fails else 0


if __name__ == "__main__":
    if sys.argv[1] == "serve":
        serve(sys.argv[2])
    else:
        sys.exit(check(sys.argv[2], sys.argv[3], sys.argv[4]))
