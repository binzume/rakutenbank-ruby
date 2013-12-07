This is a Rakuten-bank library for Ruby.
- http://www.rakuten-bank.co.jp/

作りかけ．残高は取れます．

Require:

Ruby 1.9.3 or later.

Exapmple:

# rakutenbank_account.yaml
ID: "hogehoge"
PASS: "**********"
QA:
  - q: "中学校"
    a: "だいいちちゅうがっこう"
  - q: "小学校"
    a: "ひがししょうがっこう"

アカウント名，パスワード，合言葉を設定してください．
最近ログインしたことのある環境から使う場合は合言葉は聞かれないので省略できます．

↓こんな感じに預金残高と最新の履歴だけ取得出来ます．
( rakutenbank_sample.rb )
#!/usr/bin/ruby -Ku
# -*- encoding: utf-8 -*-
#

require 'yaml'
require_relative 'rakutenbank'

account = YAML.load_file('rakutenbank_account.yaml')
rakutenbank = RakutenBank.new

# login
unless rakutenbank.login(account)
  puts 'LOGIN ERROR'
  exit
end

begin
  puts 'total: ' + rakutenbank.total_balance.to_s
  rakutenbank.recent.each do |row|
    p row
  end

ensure
  # logout
  rakutenbank.logout
end


あらゆる動作は無保証です．実装と動作をよく確認して使ってください．

