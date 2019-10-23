FROM perl:latest

ARG UID
ARG GID

RUN curl -sL --compressed https://git.io/cpm > /usr/local/bin/cpm \
    && chmod 755 /usr/local/bin/cpm

COPY cpanfile* .
RUN cpm install --global --no-show-progress --resolver 02packages,https://cpan.metacpan.org --resolver metadb

ENV HOME /app
ENV USER metadb
RUN addgroup --gid $GID $USER
RUN useradd --gid $GID --uid $UID --system --home-dir $HOME --create-home --shell /sbin/nologin -c "perlapp user" $USER
WORKDIR $HOME

EXPOSE 5000
COPY docker_entrypoint.sh /

USER metadb

COPY --chown=$USER:$USER . .

ENTRYPOINT ["/docker_entrypoint.sh"]
CMD ["./start"]
