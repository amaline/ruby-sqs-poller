FROM ruby

RUN echo "$HOME";\
    cd ~;\
    pwd;\
    echo ":ssl_verify_mode: 0" > .gemrc;\
    gem install aws-sdk -v '~> 2' ;\
    gem install json ;\
    mkdir .aws

ADD ./credentials /root/.aws/
ADD ./certs /usr/local/share/ca-certificates/
RUN update-ca-certificates

WORKDIR "/root"

ADD ./sqs_poll.rb /root/

CMD ["./sqs_poll.rb"]
