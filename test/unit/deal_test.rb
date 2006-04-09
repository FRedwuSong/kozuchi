require File.dirname(__FILE__) + '/../test_helper'

class DealTest < Test::Unit::TestCase
#  fixtures :deals
  fixtures :accounts
  fixtures :users

  def test_create_simple
    user = User.find(1)
    assert user

    # �ǉ�
    deal = Deal.create_simple(
      user.id,
      Date.parse("2006/04/01"), nil, "���ɂ���",
      105,
      1,
      2)

    deal = Deal.find(1)
    assert deal
    assert_equal user.id, deal.user_id
    assert_equal "���ɂ���", deal.summary
    assert_equal 4, deal.date.month
    assert_equal 2006, deal.date.year
    assert_equal 2, deal.account_entries.size
    assert_equal deal.account_entries[0].account_id, 1
    assert_equal deal.account_entries[0].amount, -105
    assert_equal deal.account_entries[0].deal_id, 1
    assert_equal deal.account_entries[1].account_id, 2
    assert_equal deal.account_entries[1].amount, 105
    assert_equal deal.account_entries[1].deal_id, 1
    assert_equal 1, deal.daily_seq

    # �ǉ�
    deal2 = Deal.create_simple(
      user.id,
      Date.parse("2006/04/01"), nil, "���ɂ���",
      105,
      1,
      2)

    assert_equal 2, deal2.daily_seq
    
    #2�̑O�ɑ}��
    deal3 = Deal.create_simple(
      user.id,
      Date.parse("2006/04/01"), deal2, "���ɂ���",
      105,
      1,
      2)
   
   assert_equal 2, deal3.daily_seq
   
   #deal�����̂܂܂�deal2��3�ɂȂ邱�Ƃ��m�F
   deal = Deal.find(deal.id)
   assert_equal 1, deal.daily_seq
   
   deal2 = Deal.find(deal2.id)
   assert_equal 3, deal2.daily_seq
   
    #���t�Ⴂ��ǉ�������V�K�ɂȂ邱�Ƃ��m�F
    deal4 = Deal.create_simple(
      user.id,
      Date.parse("2006/04/02"), nil, "���ɂ���",
      105,
      1,
      2)
    assert_equal 1, deal4.daily_seq
    
    #���t�Ⴂ�ɂ��}�������܂��������Ƃ��m�F
    deal5 = Deal.create_simple(
      user.id,
      Date.parse("2006/04/02"), deal4, "���ɂ���",
      105,
      1,
      2)
    assert_equal 1, deal5.daily_seq
    deal4 = Deal.find(deal4.id)
    assert_equal 2, deal4.daily_seq
    
    #���t�Ƒ}���|�C���g�������Ă��Ȃ��Ɨ�O���������邱�Ƃ��m�F
    begin
      Deal.create_simple(
        user.id,
        Date.parse("2006/04/02"), deal, "���ɂ���",
        105,
        1,
        2)
      assert false
    rescue ArgumentError
      assert true
    end
  end
end
