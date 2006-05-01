class AccountEntry < ActiveRecord::Base
  belongs_to :deal
  belongs_to :account
  validates_presence_of :amount
  attr_accessor :balance_estimated, :unknown_amount
  
  def self.delete(deal_id, user_id)
    delete_all(["deal_id = ? and user_id = ?", deal_id, user_id])
  end
  
  def self.get_for_month(user_id, account_id, year, month)
    start_inclusive = Date.new(year, month, 1)
    end_exclusive = start_inclusive >> 1
    AccountEntry.find(:all, 
      :conditions => ["et.user_id = ? and account_id =? and dl.date >= ? and dl.date < ?", user_id, account_id, start_inclusive, end_exclusive],
      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
      )
#      ,
#      :order => "dl.date desc, dl.id desc")
  end
  
  def self.balance_start(user_id, account_id, year, month)
    start_exclusive = Date.new(year, month, 1)
    return balance_at_the_start_of(user_id, account_id, start_exclusive)
  end

  def self.balance_at_the_start_of(user_id, account_id, start_exclusive)
    # �������O�̍ŐV�̎c���m�F�����擾����
    entry = AccountEntry.find(:first,
                      :conditions => ["et.user_id = ? and et.account_id = ? and dl.date < ? and et.balance is not null", user_id, account_id, start_exclusive],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id",
                      :order => "dl.date desc, dl.daily_seq")
    # �������O�Ɏc���m�F���Ȃ��ꍇ
    if !entry
      # ��������Ɏc���m�F�����邩�H
      entry = AccountEntry.find(:first,
                      :conditions => ["et.user_id = ? and et.account_id = ? and dl.date >= ? and et.balance is not null", user_id, account_id, start_exclusive],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id",
                      :order => "dl.date desc, dl.daily_seq")
      # ��������ɂ��c���m�F���Ȃ���΁A�����ȑO�̈ٓ����v���c���Ƃ���i�����c���O�Ƃ݂Ȃ��j�B�Ȃ���΂O�Ƃ���B
      if !entry
        return AccountEntry.sum("amount",
                      :conditions => ["et.user_id = ? and account_id = ? and dl.date < ?", user_id, account_id, start_exclusive],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                      ) || 0
      # ��������Ɏc���m�F������΁A���񂩂�c���m�F�܂ł̈ٓ��������̎c��������������̂�����c���Ƃ���
      else
        return entry.balance - (AccountEntry.sum("amount",
                      :conditions => ["et.user_id = ? and account_id = ? and dl.date >= ? and (dl.date < ? or (dl.date =? and dl.daily_seq < ?))", user_id, account_id, start_exclusive, entry.deal.date, entry.deal.date, entry.deal.daily_seq],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                       ) || 0)
      end
      
    # �������O�̍ŐV�c���m�F������΁A����ȍ~�̈ٓ����v�Ǝc���𑫂������̂Ƃ���B
    else
      return entry.balance + (AccountEntry.sum("amount",
                             :conditions => ["et.user_id = ? and account_id = ? and dl.date < ? and (dl.date > ? or (dl.date =? and dl.daily_seq > ?))", user_id, account_id, start_exclusive, entry.deal.date, entry.deal.date, entry.deal.daily_seq],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                             ) || 0)
    end
  end

end
