FROM python:3.11-slim

COPY docker/dashboard/requirements-dashboard.txt /tmp/requirements-dashboard.txt

RUN pip install --no-cache-dir -r /tmp/requirements-dashboard.txt

WORKDIR /opt/project

