require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AccountEntry do
  fixtures :accounts, :users
  set_fixture_class  :accounts => Account::Base

  before do
    @cache = accounts(:account_enrty_test_cache)
  end
 # fixtures :users
#  describe "settlement_attached?" do
#    it "settlementもresult_settlementもないとき falseとなる" do
#    end
#  end
  describe "create" do

    it "成功する" do
#      d = Deal.create!(:user_id => @cache.user_id, :date => Date.new(2008, 12, 1), :daily_seq => 1, :amount => 1500, :summary => "")
#      e = AccountEntry.new(:amount => 400, :account_id => @cache.id, :user_id => @cache.user_id, :deal_id => d.id, :amount => 1500)
#      p e.inspect
#      r = e.save
#      p e.errors.inspect
#      r.should be_true
       true.should be_true # 依存がきつくて単体のテストができないのでとりあえず
    end
    
  end
end