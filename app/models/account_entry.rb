class AccountEntry < ActiveRecord::Base
  belongs_to :deal,
             :class_name => 'BaseDeal',
             :foreign_key => 'deal_id'
  belongs_to :account
  belongs_to :friend_link,
             :class_name => 'DealLink',
             :foreign_key => 'friend_link_id'
  validates_presence_of :amount
  attr_accessor :balance_estimated, :unknown_amount

  # �t�����h�A��������ΐV�������
  def before_create
    create_friend_deal
  end
  
  def self.balance_start(user_id, account_id, year, month)
    start_exclusive = Date.new(year, month, 1)
    return balance_at_the_start_of(user_id, account_id, start_exclusive)
  end

  def self.balance_at_the_start_of(user_id, account_id, start_exclusive)
  
    # �������O�̍ŐV�̎c���m�F�����擾����
    entry = AccountEntry.find(:first,
                      :select => "et.*",
                      :conditions => ["et.user_id = ? and et.account_id = ? and dl.date < ? and et.balance is not null", user_id, account_id, start_exclusive],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id",
                      :order => "dl.date desc, dl.daily_seq")
    # �������O�Ɏc���m�F���Ȃ��ꍇ
    if !entry
      # ��������Ɏc���m�F�����邩�H
      entry = AccountEntry.find(:first,
                      :select => "et.*",
                      :conditions => ["et.user_id = ? and et.account_id = ? and dl.date >= ? and et.balance is not null", user_id, account_id, start_exclusive],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id",
                      :order => "dl.date, dl.daily_seq")
      # ��������ɂ��c���m�F���Ȃ���΁A�����ȑO�̈ٓ����v���c���Ƃ���i�����c���O�Ƃ݂Ȃ��j�B�Ȃ���΂O�Ƃ���B
      if !entry
        return AccountEntry.sum("amount",
                      :conditions => ["et.user_id = ? and account_id = ? and dl.date < ? and dl.confirmed = ?", user_id, account_id, start_exclusive, true],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                      ) || 0
      # ��������Ɏc���m�F������΁A���񂩂�c���m�F�܂ł̈ٓ��������̎c��������������̂�����c���Ƃ���
      else
        return entry.balance - (AccountEntry.sum("amount",
                      :conditions => [
                        "et.user_id = ? and account_id = ? and dl.date >= ? and (dl.date < ? or (dl.date =? and dl.daily_seq < ?)) and dl.confirmed = ?",
                        user_id,
                        account_id,
                        start_exclusive,
                        entry.deal.date,
                        entry.deal.date,
                        entry.deal.daily_seq,
                        true],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                       ) || 0)
      end
      
    # �������O�̍ŐV�c���m�F������΁A����ȍ~�̈ٓ����v�Ǝc���𑫂������̂Ƃ���B
    else
      return entry.balance + (AccountEntry.sum("amount",
                             :conditions => ["et.user_id = ? and account_id = ? and dl.date < ? and (dl.date > ? or (dl.date =? and dl.daily_seq > ?)) and dl.confirmed = ?",
                             user_id,
                             account_id,
                             start_exclusive,
                             entry.deal.date,
                             entry.deal.date,
                             entry.deal.daily_seq,
                             true],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                             ) || 0)
    end
  end

  private
  def create_friend_deal
    return unless !friend_link_id # ���łɂ��遁����ʂɂȂ�
    p "create_friend_deal. account = #{account.name}"
    partner_account = account.partner_account
    return unless partner_account
    p "partner_account = #{partner_account.name}"
    partner_other_account = Account.find_default_asset(partner_account.user_id)
    p "partner_other_account = #{partner_other_account.name}"
    return unless partner_other_account
    
    new_link = friend_deal_link = DealLink.create(:created_user_id => account.user_id)
    
    self.friend_link_id = new_link.id
    
    p "going to create friend_deal."
    friend_deal = Deal.new(
              :minus_account_id => partner_account.id,
              :minus_account_friend_link_id => new_link.id,
              :plus_account_id => partner_other_account.id,
              :amount => self.amount,
              :user_id => partner_account.user_id,
              :date => self.deal.date,
              :summary => self.deal.summary,
              :confirmed => false
    )
    friend_deal.save!
    p "saved friend_deal #{friend_deal.id}"
    
  end

end
