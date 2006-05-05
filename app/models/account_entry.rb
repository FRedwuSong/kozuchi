class AccountEntry < ActiveRecord::Base
  belongs_to :deal,
             :class_name => 'BaseDeal',
             :foreign_key => 'deal_id'
  belongs_to :account
  validates_presence_of :amount
  attr_accessor :balance_estimated, :unknown_amount
  
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
                      :order => "dl.date desc, dl.daily_seq")
      # ��������ɂ��c���m�F���Ȃ���΁A�����ȑO�̈ٓ����v���c���Ƃ���i�����c���O�Ƃ݂Ȃ��j�B�Ȃ���΂O�Ƃ���B
      if !entry
        return AccountEntry.sum("amount",
                      :conditions => ["et.user_id = ? and account_id = ? and dl.date < ? and dl.undecided = ?", user_id, account_id, start_exclusive, false],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                      ) || 0
      # ��������Ɏc���m�F������΁A���񂩂�c���m�F�܂ł̈ٓ��������̎c��������������̂�����c���Ƃ���
      else
        return entry.balance - (AccountEntry.sum("amount",
                      :conditions => [
                        "et.user_id = ? and account_id = ? and dl.date >= ? and (dl.date < ? or (dl.date =? and dl.daily_seq < ?)) and dl.undecided = ?",
                        user_id,
                        account_id,
                        start_exclusive,
                        entry.deal.date,
                        entry.deal.date,
                        entry.deal.daily_seq,
                        false],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                       ) || 0)
      end
      
    # �������O�̍ŐV�c���m�F������΁A����ȍ~�̈ٓ����v�Ǝc���𑫂������̂Ƃ���B
    else
      return entry.balance + (AccountEntry.sum("amount",
                             :conditions => ["et.user_id = ? and account_id = ? and dl.date < ? and (dl.date > ? or (dl.date =? and dl.daily_seq > ?)) and dl.undecided = ?",
                             user_id,
                             account_id,
                             start_exclusive,
                             entry.deal.date,
                             entry.deal.date,
                             entry.deal.daily_seq,
                             false],
                      :joins => "as et inner join deals as dl on et.deal_id = dl.id"
                             ) || 0)
    end
  end

end
