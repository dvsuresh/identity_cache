require "test_helper"

class NormalizedBelongsToTest < IdentityCache::TestCase
  def setup
    super
    AssociatedRecord.cache_belongs_to :item, :embed => false

    @parent_record = Item.new(:title => 'foo')
    @parent_record.associated_records << AssociatedRecord.new(:name => 'bar')
    @parent_record.save
    @parent_record.reload
    @record = @parent_record.associated_records.first
  end

  def test_fetching_the_association_should_delegate_to_the_normal_association_fetcher_if_any_transactions_are_open
    Item.expects(:fetch_by_id).never
    @record.transaction do
      assert_equal @parent_record, @record.fetch_item
    end
  end

  def test_fetching_the_association_should_delegate_to_the_normal_association_fetcher_if_the_normal_association_is_loaded
    # Warm the ActiveRecord association
    @record.item

    Item.expects(:fetch_by_id).never
    assert_equal @parent_record, @record.fetch_item
  end

  def test_fetching_the_association_should_fetch_the_record_from_identity_cache
    Item.expects(:fetch_by_id).with(@parent_record.id).returns(@parent_record)
    assert_equal @parent_record, @record.fetch_item
  end

  def test_fetching_the_association_should_assign_the_result_to_the_association_so_that_successive_accesses_are_cached
    Item.expects(:fetch_by_id).with(@parent_record.id).returns(@parent_record)
    @record.fetch_item
    assert @record.association(:item).loaded?
    assert_equal @parent_record, @record.item
  end

  def test_fetching_the_association_shouldnt_raise_if_the_record_cant_be_found
    Item.expects(:fetch_by_id).with(@parent_record.id).returns(nil)
    assert_equal nil, @record.fetch_item
  end
end
