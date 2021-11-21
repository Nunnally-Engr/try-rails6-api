FROM ruby:2.7.3-alpine
RUN apk update \
      && apk add --no-cache gcc make libc-dev g++ mariadb-dev tzdata nodejs~=14 yarn \
      && mkdir /try-rails6-api
WORKDIR /try-rails6-api
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install --jobs=2
COPY . /try-rails6-api

COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000
CMD ["bundle","exec","rails", "server", "-b", "0.0.0.0"]
