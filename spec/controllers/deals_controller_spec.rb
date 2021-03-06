# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require File.expand_path(File.dirname(__FILE__) + '/../controller_spec_helper')

describe DealsController, type: :controller do
  fixtures :users, :preferences, :accounts
  before do
    login_as :taro
  end
  describe "index" do
    it "monthlyにリダイレクトされる" do
      get :index
      expect(response).to redirect_to monthly_deals_path(:year => Date.today.year, :month => Date.today.month)
    end
  end
  describe "monthly" do
    it "成功する" do
      get :monthly, params: {year: '2010', month: '4'}
      expect(response).to be_success
    end
  end
  describe "new_general_deal" do
    it "成功する" do
      get :new_general_deal
      expect(response).to be_success
    end
  end
  describe "create_general_deal" do
    it "成功する" do
      # 貸し方の金額ははいらない
      post :create_general_deal,
           params: {
               deal: {
                   year: '2010', month: '7', day: '7',
                   summary: 'test',
                   summary_mode: 'unify',
                   creditor_entries_attributes: [{:account_id => :taro_cache.to_id}],
                   debtor_entries_attributes: [{:account_id => :taro_bank.to_id, :amount => 1000}]
               }

           }
      expect(response).to be_success
      deal = @current_user.general_deals.where(date: Date.new(2010, 7, 7)).order(created_at: :desc).first
      expect(deal).not_to be_nil
      expect(deal.debtor_entries.size).to eq 1
      expect(deal.creditor_entries.size).to eq 1
      expect(deal.debtor_entries.first.summary).to eq 'test'
      expect(deal.creditor_entries.first.summary).to eq 'test'
    end
  end
  describe "new_complex_deal" do
    it "成功する" do
      get :new_complex_deal
      expect(response).to be_success
    end
  end
  describe "create_complex_deal" do
    it "成功する" do
      post :create_complex_deal,
           params: {
               deal: {
                   year: '2010', month: '7', day: '9',
                   summary: 'test_complex',
                   summary_mode: 'unify',
                   creditor_entries_attributes: [{:account_id => :taro_cache.to_id, :amount => -800, :line_number => 0}, {:account_id => :taro_hanako.to_id, :amount => -200, :line_number => 1}],
                   debtor_entries_attributes: [{:account_id => :taro_bank.to_id, :amount => 1000, :line_number => 0}]
               }
           }
      expect(response).to be_success
      deal = @current_user.general_deals.where(date: Date.new(2010, 7, 9)).order(created_at: :desc).first
      expect(deal).not_to be_nil
      expect(deal.debtor_entries.size).to eq 1
      expect(deal.creditor_entries.size).to eq 2
      expect(deal.debtor_entries.first.summary).to eq 'test_complex'
      expect(deal.creditor_entries.first.summary).to eq 'test_complex'
      expect(deal.creditor_entries.last.summary).to eq 'test_complex'
    end
  end
  describe "new_balance_deal" do
    it "成功する" do
      get :new_balance_deal
      expect(response).to be_success
    end
  end
  describe "create_balance_deal" do
    it "成功する" do
      post :create_balance_deal, params: {
          :account_id => :taro_cache.to_id, :deal => {
              :balance => 3000,
              :account_id => :taro_cache.to_id,
              :year => '2010', :month => '7', :day => '7'
          }
      }
      expect(response).to be_success
      deal = @current_user.balance_deals.find_by(date: Date.new(2010, 7, 7))
      expect(deal).not_to be_nil
      expect(deal.balance).to eq 3000
    end
  end

  describe "search" do
    it "成功する" do
      get :search, params: {:keyword => 'test'}
      expect(response).to be_success
    end
    it "キーワードなしだとエラーとなる" do
      expect{get :search}.to raise_error(InvalidParameterError)
    end
  end

  describe "destroy" do
    before do
      @deal = create_deal
    end
    it "成功する" do
      delete :destroy, params: {:id => @deal.id}
      expect(response).to be_success
      expect(Deal::Base.find_by(id: @deal.id)).to be_nil
    end
  end

  describe "confirm" do
    before do
      @deal = create_deal(:confirmed => false)
    end
    it "成功する" do
      post :confirm, params: {:id => @deal.id}
      expect(response).to be_success
      @deal.reload
      expect(@deal).to be_confirmed
    end
  end

  describe "edit" do
    before do
      @deal = create_deal(:confirmed => false)
    end
    it "成功する" do
      get :edit, params:  {:id => @deal.id}
      expect(response).to be_success
    end
  end

  describe "update" do
    before do
      @deal = create_deal(:confirmed => false)
    end
    it "成功する" do
      put :update, params: {
            :id => @deal.id, :deal => {
            :year => '2010', :month => '7', :day => '9',
            :summary => 'changed like test_complex',
            :summary_mode => 'unify',
            :creditor_entries_attributes => {'0' => {:account_id => :taro_cache.to_id, :amount => -800, :line_number => 0}, '1' => {:account_id => :taro_hanako.to_id, :amount => -200, :line_number => 1}},
            :debtor_entries_attributes => {'0' => {:account_id => :taro_bank.to_id, :amount => 1000, :line_number => 0}}
          }
      }
      expect(response).to be_success
      @deal.reload
      expect(@deal.creditor_entries.size).to eq 2
      expect(@deal.summary).to eq 'changed like test_complex'
      expect(@deal.date).to eq Date.new(2010, 7, 9)
    end
  end

  describe "create_entry" do
    context "新しいDealに対して" do
      it "成功する" do
        post :create_entry, params: {
            :id => 'new', :deal => {
            :year => '2010', :month => '7', :day => '9',
            :summary => 'changed like test_complex',
            :creditor_entries_attributes => {'0' => {:account_id => :taro_cache.to_id, :amount => -800}, '1' => {:account_id => :taro_hanako.to_id, :amount => -200}},
            :debtor_entries_attributes => {'0' => {:account_id => :taro_bank.to_id, :amount => 1000}}
            }
        }
        expect(response).to be_success
      end
    end

    context "既存のDealに対して" do
      before do
        @deal = create_deal
      end
      it "成功する" do
        post :create_entry, params: {
            :id => @deal.id, :deal => {
            :year => '2010', :month => '7', :day => '9',
            :summary => 'changed like test_complex',
            :creditor_entries_attributes => {'0' => {:account_id => :taro_cache.to_id, :amount => -800}, '1' => {:account_id => :taro_hanako.to_id, :amount => -200}},
            :debtor_entries_attributes => {'0' => {:account_id => :taro_bank.to_id, :amount => 1000}}
            }
        }
        expect(response).to be_success
      end
    end
  end


  private
  def create_deal(attributes = {})
    deal = @current_user.general_deals.build({:summary => 'in created_deal',
      :summary_mode => 'unify',
      :year => '2010', :month => '7', :day => '8',
      :debtor_entries_attributes => [{:account_id => :taro_food.to_id, :amount => 500}],
      :creditor_entries_attributes => [{:account_id => :taro_cache.to_id, :amount => -500}]}.merge(attributes))
    deal.save!
    deal
  end

end
