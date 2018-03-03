# jhthorsen/linkembedder
#
# BUILD: docker build --no-cache --rm -t jhthorsen/linkembedder .
# RUN:   docker run -it --rm -p 8080:8080 jhthorsen/linkembedder
FROM alpine:3.5
MAINTAINER jhthorsen@cpan.org

RUN apk add -U perl perl-io-socket-ssl \
  && apk add -t builddeps build-base curl perl-dev wget \
  && curl -L https://github.com/jhthorsen/app-linkembedder/archive/master.tar.gz | tar xvz \
  && curl -L https://cpanmin.us | perl - App::cpanminus \
  && cpanm -M https://cpan.metacpan.org --installdeps ./app-linkembedder-master \
  && apk del builddeps curl \
  && rm -rf /root/.cpanm /var/cache/apk/*

ENV MOJO_MODE production
ENV LINK_EMBEDDER_RESTRICTED 1
EXPOSE 8080

ENTRYPOINT ["/app-linkembedder-master/examples/embedder.pl", "prefork", "-l", "http://*:8080"]
