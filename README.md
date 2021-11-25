# Rails 6.0 + Docker + MySQL5x での環境構築

## 各種バージョン

- Ruby 2.7
- Rails 6.0.0
- mysql 5.7.21

---

## 参考リンク

- [【Rails】Rails 6.0 x Docker x MySQLで環境構築](https://qiita.com/nsy_13/items/9fbc929f173984c30b5d)

---

## 前提条件

- Dockerを使える環境が整っていること

---

## 環境構築手順

### 1. 各種ファイルを準備する

#### .env ※ パスワードは各自で変更してください

```
DB_PASSWORD="xxxxxx"
DB_PASSWORD_PRODUCTION="xxxxxx"
```

#### docker-compose.yml

```
version: "3.9"
services:
  db:
    image: mysql:5.7.21
    environment:
      MYSQL_ROOT_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db-volume:/var/lib/mysql
    ports:
      - "3306:3306"
  back:
    build: .
    command: >
      ash -c "rm -f tmp/pids/server.pid &&
      bundle exec rails s -p 4000 -b '0.0.0.0'"
    volumes:
      - .:/try-rails6-api
    ports:
      - "4000:4000"
    env_file:
      - .env
    depends_on:
      - db
volumes:
  db-volume:
    driver: local
```

#### Dockerfile

```
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
```

#### entrypoint.sh

```
#!/bin/sh
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /myapp/tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@"
```

#### Gemfile

```
source 'https://rubygems.org'
gem 'rails', '~>6'
```

#### Gemfile.lock

```
# 何も記述しない空ファイルのままでOK
```

### 2. rails new でアプリ作成

```
docker-compose run back rails new . --force --no-deps --database=mysql --skip-test --webpacker
```

### 3. イメージのビルド

```
docker-compose build
```

### 4. database.yml の設定と DB 接続

#### config/database.yml
```
default: &default
  adapter: mysql2
  encoding: utf8mb4
  charset: utf8mb4
  collation: utf8mb4_unicode_520_ci
  pool: 15
  username: root
  password: <%= ENV['DB_PASSWORD'] %>
  host: db

development:
  <<: *default
  database: rails_api_development

test:
  <<: *default
  database: rails_api_test

production:
  <<: *default
  database: rails_api_production
  username: rails_api
  password: <%= ENV['DB_PASSWORD_PRODUCTION'] %>
  host: 127.0.0.1
```

#### データベースの作成

```
docker-compose run back rake db:create
```

### 5. 疎通確認用のRouting作成

### 1. SessionsController 作成 ※ 不要なものをgeneratorで生成しない

```
docker-compose run back rails g controller v1/sessions healthcheck  --no-assets --no-helper
```

### 2. app/controllers/v1/sessions_controller.rb を 書き換える

```
module V1
  class SessionsController < ApplicationController
    def healthcheck
      render json: { status: :success }
    end
  end
end
```

### 3. config/routes.rb を 書き換える

```
Rails.application.routes.draw do
  namespace :v1, defaults: { format: :json } do
    get :healthcheck, to: 'sessions#healthcheck'
  end
end
```

---

## 疎通確認

### 1. コンテナ起動

```
docker-compose up
```

### 2. ブラウザもしくはPostmanなどのWeb APIのテストクライアントサービスで以下のURLを実行し、 `{ status: :success }` が表示されれば疎通成功

```
http://localhost:4000/v1/healthcheck
```

