FROM python:3.6-alpine

WORKDIR /opt

COPY app.py .
COPY templates/ ./templates/
COPY static/ ./static/
COPY releases.txt .

RUN pip install --no-cache-dir Flask==1.1.4 Werkzeug==1.0.1 Jinja2==2.11.3 itsdangerous==1.1.0 click==7.1.2 MarkupSafe==2.0.1

RUN awk -F': ' '$1 == "ODOO_URL" { print "export DEFAULT_ODOO_URL=\"" $2 "\"" } $1 == "PGADMIN_URL" { print "export DEFAULT_PGADMIN_URL=\"" $2 "\"" }' releases.txt > /opt/releases.env

EXPOSE 8080

ENTRYPOINT ["/bin/sh", "-c", ". /opt/releases.env && export ODOO_URL=\"${ODOO_URL:-$DEFAULT_ODOO_URL}\" PGADMIN_URL=\"${PGADMIN_URL:-$DEFAULT_PGADMIN_URL}\" && exec python app.py"]