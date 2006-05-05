class AccountEntry < ActiveRecord::Base
  belongs_to :deal,
             :class_name => 'BaseDeal',
             :foreign_key => 'deal_id'
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
    # �Ȃ����Ƃ��̂� Balance �ɁB�B�B
  
    # �������O�̍ŐV�̎c���m�F�����擾����
    balance = AccountEntry.find(:first,
                      :conditions => ["et.user_id = ? and et.account_id = ? and dl.date < ? and et.balance is not null", user_id, account_id, start_exclusive],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id",
                      :order => "dl.date desc, dl.daily_seq")
    p "balance = #{balance}"
    # �������O�Ɏc���m�F���Ȃ��ꍇ
    if !balance
      # ��������Ɏc���m�F�����邩�H
      balance = AccountEntry.find(:first,
                      :conditions => ["et.user_id = ? and et.account_id = ? and dl.date >= ? and et.balance is not null", user_id, account_id, start_exclusive],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id",
                      :order => "dl.date desc, dl.daily_seq")
    p "balance = #{balance}"
      # ��������ɂ��c���m�F���Ȃ���΁A�����ȑO�̈ٓ����v���c���Ƃ���i�����c���O�Ƃ݂Ȃ��j�B�Ȃ���΂O�Ƃ���B
      if !balance
        return AccountEntry.sum("amount",
                      :conditions => ["et.user_id = ? and account_id = ? and dl.date < ? and dl.undecided = ?", user_id, account_id, start_exclusive, false],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                      ) || 0
      # ��������Ɏc���m�F������΁A���񂩂�c���m�F�܂ł̈ٓ��������̎c��������������̂�����c���Ƃ���
      else
      # �Ȃ� entry ����Ȃ��H�H
    p "balance = #{balance}"
    p "balance.date = #{balance.date}"
    p "balance.balance = #{balance.balance}"
    
        return balance.balance - (AccountEntry.sum("amount",
                      :conditions => ["et.user_id = ? and account_id = ? and dl.date >= ? and (dl.date < ? or (dl.date =? and dl.daily_seq < ?)) and dl.undecided = ?", user_id, account_id, start_exclusive, balance.date, balance.date, balance.daily_seq, false],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                       ) || 0)
      end
      
    # �������O�̍ŐV�c���m�F������΁A����ȍ~�̈ٓ����v�Ǝc���𑫂������̂Ƃ���B
    else
      return balance.balance + (AccountEntry.sum("amount",
                             :conditions => ["et.user_id = ? and account_id = ? and dl.date < ? and (dl.date > ? or (dl.date =? and dl.daily_seq > ?)) and dl.undecided = ?", user_id, account_id, start_exclusive, balance.date, balance.date, balance.daily_seq, false],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                             ) || 0)
    end
  end

end
