# -*- encoding: utf-8 -*-
#
#  楽天銀行
#  Rakuten-bank client
#
# @author binzume  http://www.binzume.net/
#

require 'kconv'
require 'time'
require_relative 'httpclient'

class RakutenBank
  attr_reader :account_status, :accounts, :funds, :last_html
  attr_accessor :account

  def initialize(account = nil)
    @account_status = {:total=>nil}
    @url = 'https://fes.rakuten-bank.co.jp/'
    ua = "Mozilla/5.0 (Windows; U; Windows NT 5.1;) PowerDirectBot/0.1"
    @client = HTTPClient.new(:agent_name => ua)

    if account
      login(account)
    end
  end

  ##
  # ログイン
  #
  # @param [Hash] account アカウント情報(see rakuten_account.yaml.sample)
  def login(account)
    @account = account

    res = @client.get(@url+'/MS/main/RbS?CurrentPageID=START&&COMMAND=LOGIN')

    postdata = {
      'LOGIN_SUBMIT'=>'1',
      'jsf_sequence'=>'1',
      'LOGIN:_link_hidden_'=>'',
      'LOGIN:_idJsp79'=>'',
      'LOGIN_SUBMIT'=>'1',
      'LOGIN:USER_ID'=>account['ID'],
      'LOGIN:LOGIN_PASSWORD'=>account['PASS']
    }

    # MS/main/fcs/rb/fes/jsp/mainservice/Security/LoginAuthentication/Login/Login.jsp


    res = @client.post(@url + 'MS/main/fcs/rb/fes/jsp/mainservice/Security/LoginAuthentication/Login/Login.jsp', postdata)
    if res.header['location']
      # error
      p res.header['location']
      return nil
    end

    if res.body =~ /INPUT_FORM:SECRET_WORD/
      q = ""
      if res.body.toutf8 =~ /質問<.*?>\s*([^\s<]+)\s*</m
        q = $1.strip
      end

      raise "Aikotoba required! : " + q
      # FIXME!!
      postdata = {
        'INPUT_FORM_SUBMIT'=>'1',
        'jsf_sequence'=>'2',
        'INPUT_FORM:_link_hidden_'=>'',
        'INPUT_FORM:_idJsp136' => 'INPUT_FORM:_idJsp136',
        'INPUT_FORM:SECRET_WORD' => 'hoge'
      }
      res = @client.post(@url + '/MS/main/fcs/rb/fes/jsp/commonservice/Security/LoginAuthentication/SecretWordAuthentication/SecretWordAuthentication.jsp', postdata)
    end

    res = @client.get(@url + 'MS/main/gns?COMMAND=BALANCE_INQUIRY_START&&CurrentPageID=HEADER_FOOTER_LINK')
    #puts res.body

    account_status = {
      :name => get_match(res.body, />\s+([^<]+?)\s+様\s+</),
      :branch => get_match(res.body, />\s+支店番号\s+([^<]+?)\s+</),
      :acc_num => get_match(res.body, />\s+口座番号\s+([^<]+?)\s+</),
      :last_login => get_match(res.body, />\s+前回ログイン日時\s+([^<]+?)\s+</),
      :total => get_match(res.body.toutf8, /普通預金残高.*?>\s*([0-9,]+)\s*</m).gsub(/,/,'').to_i
    }

    @account_status = account_status

    account_status
  end

  ##
  # ログアウト
  def logout
    res = @client.get(@url + 'MS/main/gns?COMMAND=LOGOUT_START&&CurrentPageID=HEADER_FOOTER_LINK')
    #p res
    #puts res.body
  end

  ##
  # 残高確認
  #
  # @return [int] 残高(yen)
  def total_balance
    @account_status[:total]
  end

  ##
  # 直近の取引履歴(円口座)
  #
  # @return [Array] 履歴の配列
  def recent
    get_history nil, nil
  end

  def get_accounts
    [@account_status]
  end

  def get_history from,to

    postdata = {
      'FORM_SUBMIT'=>'1',
      'jsf_sequence'=>'4',
      'FORM:_link_hidden_'=>'FORM:_idJsp136'
    }
    #p postdata
    res = @client.post(@url + 'MS/main/fcs/rb/fes/jsp/mainservice/Inquiry/BalanceInquiry/BalanceInquiry/BalanceInquiry.jsp', postdata)
    #puts res.body


    history = []

    res.body.scan(/<tr class="td\d\dline">(.*?)<\/tr>/m) { m = Regexp.last_match
        cells = []
        m[1].scan(/<td[^>]*>(.*?)<\/td>/m){  mm = Regexp.last_match
          cells << mm[1].gsub(/<[^>]*>/,'').strip
        }
        history << {
          :date => cells[0],
          :description => cells[1],
          :amount => cells[2],
          :barance => cells[3]
        }
    }

    history
  end

  ##
  # transfer to registered account
  #
  # @param [string] name = target 7digit account num. TODO:口座番号被る可能性について考える
  # @param [int] amount < 2000000 ?
  def transfer_to_registered_account name, amount, confirm = false

    raise 'not implemented'

  end


  private
  def get_match(str,reg)
    if str.toutf8 =~ reg
      return $1
    end
    nil
  end

end

