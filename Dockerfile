FROM perl:latest

ARG APPUID
ARG APPGID

RUN curl -sL --compressed https://raw.githubusercontent.com/skaji/cpm/master/cpm > /usr/local/bin/cpm \
    && chmod 755 /usr/local/bin/cpm

COPY cpanfile* .
RUN cpm install --global --no-show-progress --resolver 02packages,https://cpan.metacpan.org --resolver metadb

ENV HOME /app
ENV USER metadb
RUN addgroup --gid $APPGID $USER
RUN useradd --gid $APPGID --uid $APPUID --system --home-dir $HOME --create-home --shell /sbin/nologin -c "perlapp user" $USER
WORKDIR $HOME

EXPOSE 5000
COPY docker_entrypoint.sh /

USER metadb

COPY --chown=$USER:$USER . .

ENTRYPOINT ["/docker_entrypoint.sh"]
CMD ["./start"]
