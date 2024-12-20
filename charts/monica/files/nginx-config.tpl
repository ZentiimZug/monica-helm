upstream php-handler {
    server 127.0.0.1:9000;
}

server {
    listen {{ .Values.nginx.containerPort | default 80 }};
    listen [::]:{{ .Values.nginx.containerPort | default 80 }};

    ## HSTS ##
    # Add the 'Strict-Transport-Security' headers to enable HSTS protocol.
    # WARNING: Only add the preload option once you read about the consequences: https://hstspreload.org/.
    # This form will add the domain to a hardcoded list that is shipped in all major browsers and getting
    # removed from this list could take several months.
    #
    #add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload;" always;

    add_header Referrer-Policy "no-referrer" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Download-Options "noopen" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Permitted-Cross-Domain-Policies "none" always;
    add_header X-Robots-Tag "none" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Remove X-Powered-By, which is an information leak
    fastcgi_hide_header X-Powered-By;

    root /var/www/html/public;

    index index.php index.html index.htm;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ ^/(?:robots.txt|security.txt) {
        allow all;
        log_not_found off;
        access_log off;
    }

    error_page 404 500 502 503 504 /index.php;

    location ~ /\.well-known/(?:carddav|caldav) {
        return 301 $scheme://$host/dav;
    }
    location = /.well-known/security.txt {
        return 301 $scheme://$host/security.txt;
    }
    location ~ /\.(?!well-known).* {
        deny all;
    }

    # set max upload size
    client_max_body_size 10G;
    fastcgi_buffers 64 8K;
    fastcgi_buffer_size 32k;

    # Enable gzip but do not remove ETag headers
    gzip on;
    gzip_vary on;
    gzip_comp_level 4;
    gzip_min_length 256;
    gzip_proxied expired no-cache no-store private no_last_modified no_etag auth;
    gzip_types application/atom+xml application/javascript application/json application/ld+json application/manifest+json application/rss+xml application/vnd.geo+json application/vnd.ms-fontobject application/x-font-ttf application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/bmp image/svg+xml image/x-icon text/cache-manifest text/css text/plain text/vcard text/vnd.rim.location.xloc text/vtt text/x-component text/x-cross-domain-policy;

    # Uncomment if your server is build with the ngx_pagespeed module
    # This module is currently not supported.
    #pagespeed off;

    location ~ \.php(?:$|/) {
        # regex to split $uri to $fastcgi_script_name and $fastcgi_path
        fastcgi_split_path_info ^(.+?\.php)(/.*)$;

        # Check that the PHP script exists before passing it
        try_files $fastcgi_script_name =404;

        fastcgi_pass php-handler;
        fastcgi_index index.php;

        include fastcgi_params;

        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        # Bypass the fact that try_files resets $fastcgi_path_info
        # see: http://trac.nginx.org/nginx/ticket/321
        set $path_info $fastcgi_path_info;
        fastcgi_param PATH_INFO $path_info;
    }

    # Adding the cache control header for js and css files
    # Make sure it is BELOW the PHP block
    location ~ \.(?:css|js|woff2?|svg|gif|json)$ {
        try_files $uri /index.php$request_uri;
        add_header Cache-Control "public, max-age=15778463";

        ## HSTS ##
        # Add the 'Strict-Transport-Security' headers to enable HSTS protocol.
        # Note it is intended to have those duplicated to the ones above.
        # WARNING: Only add the preload option once you read about the consequences: https://hstspreload.org/.
        # This form will add the domain to a hardcoded list that is shipped in all major browsers and getting
        # removed from this list could take several months.
        #
        #add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload;" always;

        add_header Referrer-Policy "no-referrer" always;
        add_header X-Content-Type-Options "nosniff" always;
        add_header X-Download-Options "noopen" always;
        add_header X-Frame-Options "SAMEORIGIN" always;
        add_header X-Permitted-Cross-Domain-Policies "none" always;
        add_header X-Robots-Tag "none" always;
        add_header X-XSS-Protection "1; mode=block" always;

        # Optional: Don't log access to assets
        access_log off;
    }

    location ~ \.(?:png|html|ttf|ico|jpg|jpeg)$ {
        try_files $uri /index.php$request_uri;

        # Optional: Don't log access to assets
        access_log off;
    }

    # deny access to .htaccess files
    location ~ /\.ht {
        deny all;
    }
}
