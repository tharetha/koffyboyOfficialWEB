# ─── Frontend Web Server (Nginx) ──────────────────────────
FROM nginx:alpine

# Copy the static frontend files to the Nginx html directory
COPY . /usr/share/nginx/html

# Copy our custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
