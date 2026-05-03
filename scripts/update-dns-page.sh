#!/usr/bin/env bash
set -euo pipefail

ZONE="home.app"
DNS_SERVER="root@192.168.1.9"
PDNS_CONTAINER="powerdns"

PROJECT_DIR="/root/homelabwebgui"
OUTPUT_FILE="$PROJECT_DIR/html/dns.html"
TMP_ZONE="/tmp/${ZONE}.zone"

echo "[INFO] DNS Zone wird von $DNS_SERVER gelesen..."

ssh "$DNS_SERVER" "docker exec $PDNS_CONTAINER pdnsutil list-zone $ZONE" > "$TMP_ZONE"

SERIAL="$(date +%Y%m%d%H%M)"
UPDATED_AT="$(date '+%d.%m.%Y %H:%M:%S')"

echo "[INFO] Erstelle HTML-Datei: $OUTPUT_FILE"

cat > "$OUTPUT_FILE" <<EOF
<!doctype html>
<html lang="de" data-bs-theme="dark">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>DNS Records - $ZONE</title>

    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">

    <style>
        body {
            background: #0f172a;
        }

        .hero {
            background: linear-gradient(135deg, #111827, #1e293b);
            border: 1px solid #334155;
        }

        .code-block {
            background: #020617;
            color: #e5e7eb;
            border-radius: 1rem;
            padding: 1rem;
            overflow: auto;
            font-size: 0.9rem;
        }

        .table-card {
            border-radius: 1rem;
            overflow: hidden;
        }

        .record-value {
            font-family: Consolas, monospace;
            word-break: break-all;
        }
    </style>
</head>

<body>

<nav class="navbar navbar-expand-lg bg-body border-bottom sticky-top">
    <div class="container">
        <a class="navbar-brand fw-bold" href="/">Markus Homelab</a>

        <div class="d-flex gap-2">
            <a href="/" class="btn btn-outline-secondary btn-sm">Dashboard</a>
            <button id="themeToggle" class="btn btn-primary btn-sm">Light Mode</button>
        </div>
    </div>
</nav>

<main class="container py-4 py-lg-5">

    <section class="hero rounded-4 p-4 p-lg-5 mb-4 shadow-sm">
        <span class="badge text-bg-success mb-3">Auto Generated</span>
        <h1 class="display-6 fw-bold mb-2">DNS Zone Records</h1>
        <p class="text-body-secondary mb-0">
            Automatisch generierte Übersicht für <code>$ZONE</code>
        </p>
        <div class="small text-body-secondary mt-3">
            Letztes Update: $UPDATED_AT · Serial: $SERIAL
        </div>
    </section>

    <section class="card border-0 shadow-sm table-card mb-4">
        <div class="card-header bg-body d-flex flex-column flex-md-row justify-content-between gap-3">
            <div>
                <h2 class="h5 mb-1">Records</h2>
                <p class="text-body-secondary small mb-0">A, NS, SOA, CNAME, MX, TXT und weitere Records.</p>
            </div>

            <div class="d-flex gap-2">
                <input id="searchInput" type="search" class="form-control form-control-sm" placeholder="Suchen...">
                <button id="copyBtnTop" class="btn btn-primary btn-sm">Copy</button>
            </div>
        </div>

        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th>Name</th>
                        <th>TTL</th>
                        <th>Class</th>
                        <th>Type</th>
                        <th>Value</th>
                    </tr>
                </thead>
                <tbody id="recordsTable">
EOF

awk '
BEGIN {
    OFS="";
}
$1 ~ /^\$/ {
    next;
}
NF >= 5 {
    name=$1;
    ttl=$2;
    class=$3;
    type=$4;

    value="";
    for (i=5; i<=NF; i++) {
        value = value $i;
        if (i<NF) value = value " ";
    }

    badge="secondary";
    if (type=="A") badge="primary";
    else if (type=="AAAA") badge="info";
    else if (type=="NS") badge="warning";
    else if (type=="SOA") badge="danger";
    else if (type=="CNAME") badge="success";
    else if (type=="MX") badge="dark";
    else if (type=="TXT") badge="secondary";

    printf "                    <tr>\n";
    printf "                        <td class=\"record-value\">%s</td>\n", name;
    printf "                        <td>%s</td>\n", ttl;
    printf "                        <td>%s</td>\n", class;
    printf "                        <td><span class=\"badge text-bg-%s\">%s</span></td>\n", badge, type;
    printf "                        <td class=\"record-value\">%s</td>\n", value;
    printf "                    </tr>\n";
}
' "$TMP_ZONE" >> "$OUTPUT_FILE"

cat >> "$OUTPUT_FILE" <<EOF
                </tbody>
            </table>
        </div>
    </section>

    <section class="card border-0 shadow-sm rounded-4">
        <div class="card-header bg-body d-flex justify-content-between align-items-center">
            <div>
                <h2 class="h5 mb-1">Raw Zone Text</h2>
                <p class="text-body-secondary small mb-0">Direkt kopierbar für Dokumentation oder Debugging.</p>
            </div>

            <button id="copyBtn" class="btn btn-outline-primary btn-sm">Copy raw</button>
        </div>

        <div class="card-body">
            <pre id="rawZone" class="code-block mb-0">
EOF

sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' "$TMP_ZONE" >> "$OUTPUT_FILE"

cat >> "$OUTPUT_FILE" <<EOF
</pre>
        </div>
    </section>

</main>

<footer class="border-top py-4">
    <div class="container text-center text-body-secondary small">
        Markus Homelab · DNS Auto Updater · $ZONE
    </div>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>

<script>
    const html = document.documentElement;
    const themeToggle = document.getElementById("themeToggle");
    const savedTheme = localStorage.getItem("theme");

    if (savedTheme) {
        html.setAttribute("data-bs-theme", savedTheme);
        themeToggle.textContent = savedTheme === "dark" ? "Light Mode" : "Dark Mode";
    }

    themeToggle.addEventListener("click", () => {
        const currentTheme = html.getAttribute("data-bs-theme");
        const newTheme = currentTheme === "dark" ? "light" : "dark";

        html.setAttribute("data-bs-theme", newTheme);
        localStorage.setItem("theme", newTheme);

        themeToggle.textContent = newTheme === "dark" ? "Light Mode" : "Dark Mode";
    });

    function copyZoneText() {
        const text = document.getElementById("rawZone").innerText;

        if (navigator.clipboard) {
            navigator.clipboard.writeText(text).then(() => {
                alert("Zone text copied");
            });
        } else {
            const ta = document.createElement("textarea");
            ta.value = text;
            document.body.appendChild(ta);
            ta.select();
            document.execCommand("copy");
            ta.remove();
            alert("Zone text copied");
        }
    }

    document.getElementById("copyBtn").addEventListener("click", copyZoneText);
    document.getElementById("copyBtnTop").addEventListener("click", copyZoneText);

    document.getElementById("searchInput").addEventListener("input", function () {
        const search = this.value.toLowerCase();
        const rows = document.querySelectorAll("#recordsTable tr");

        rows.forEach(row => {
            row.style.display = row.innerText.toLowerCase().includes(search) ? "" : "none";
        });
    });
</script>

</body>
</html>
EOF

rm -f "$TMP_ZONE"

echo "[OK] DNS HTML wurde aktualisiert: $OUTPUT_FILE"