require File.dirname(__FILE__) + '/../test_helper'

class FriendDealTest < Test::Unit::TestCase
  fixtures :users
  fixtures :friends
  fixtures :accounts
  fixtures :account_links
  
  # �t�����h����̃e�X�g
  def test_not_confirmed
    # �쐬
    first_deal = Deal.new(
      :summary => 'second �֑݂���',
      :amount => 1000,
      :minus_account_id => 1,
      :plus_account_id => 3,
      :user_id => 1,
      :date => Date.parse("2006/05/01")
    )
    first_deal.save!
    first_deal = Deal.find(first_deal.id)

    first_second_entry = first_deal.entry(3)
    assert first_second_entry.friend_link
    friend_link = first_second_entry.friend_link # ���Ƃł���
    another_entry = first_second_entry.friend_link.another(first_second_entry.id)
    assert_equal 2, another_entry.user_id 
    assert_equal 5, another_entry.account_id
    assert 1000*(-1), another_entry.amount
    
    # ���肪���m��ȏ�Ԃŋ��z��ύX�����瑊����ς��
    first_deal.attributes = {:amount => 1200}
    first_deal.save!

    # �ȑO�̑���͍폜����Ă���
    assert !AccountEntry.find(:first, :conditions => "id = #{another_entry.id}")

    # ��蒼�����̂łƂ�Ȃ���
    another_entry = first_second_entry.friend_link.another(first_second_entry.id)
    assert another_entry
    
    friend_link = first_second_entry.friend_link # ���Ƃł���
    assert friend_link
    friend_link_id = friend_link.id
    
    another_entry = AccountEntry.find(another_entry.id)
    assert_equal 1200*(-1), another_entry.amount 
    
    # ���肪���m��ȏ�Ԃō폜�����瑊��͏�����
    first_deal.destroy
    another_entry = AccountEntry.find(:first, :conditions => "id = #{another_entry.id}")
    assert !another_entry
    assert !DealLink.find(:first, :conditions => "id = #{friend_link_id}")
    
  end
  
  def test_confirmed
    # �쐬
    first_deal = Deal.new(
      :summary => 'second �Ɏ؂肽',
      :amount => 1000,
      :minus_account_id => 3,
      :plus_account_id => 1,
      :user_id => 1,
      :date => Date.parse("2006/05/02")
    )
    first_deal.save!
    first_deal = Deal.find(first_deal.id)

    first_second_entry = first_deal.entry(3)
    assert first_second_entry.friend_link
    friend_link_id = first_second_entry.friend_link.id # ���Ƃł���
    another_entry = first_second_entry.friend_link.another(first_second_entry.id)
    assert_equal 2, another_entry.user_id 
    assert_equal 5, another_entry.account_id
    assert 1000, another_entry.amount

    # ������m��ɂ���
    friend_deal = another_entry.deal
    friend_deal.confirm
    
    friend_deal = another_entry.deal(true) # �Ƃ�Ȃ���
    
    assert friend_deal.confirmed
    
    assert friend_deal.entry(5).friend_link
    
    # �ύX������A�V�������肪�ł���B������̓����N�������B
    first_deal.attributes = {:amount => 1200}
    first_deal.save!
    
    friend_deal = Deal.find(friend_deal.id)
    assert !friend_deal.entry(5).friend_link # �����N�����ꂽ�͂��B
    
    assert !DealLink.find(:first, :conditions => "id = #{friend_link_id}")
    
    # �V�������肪�ł����͂��B
    first_second_entry = first_deal.entry(3)
    new_friend_link = first_second_entry.friend_link
    
    assert new_friend_link.id != friend_link_id
    new_friend_link_id = new_friend_link.id
    
    new_another_entry = new_friend_link.another(first_second_entry.id)
    
    assert new_another_entry
    assert_equal 1200, new_another_entry.amount
    
    # �V����������m��ɂ���
    new_friend_deal = new_another_entry.deal
    new_friend_deal.confirmed = true
    new_friend_deal.save!
    
    # �V����������폜����Ǝ����̃����N�͂����邪�����͎c��
    new_friend_deal.destroy
    
    first_deal = Deal.find(first_deal.id)
    
    assert !first_deal.entry(3).friend_link
    
    assert !DealLink.find(:first, :conditions => "id = #{new_friend_link_id}")
    
  end
  
end