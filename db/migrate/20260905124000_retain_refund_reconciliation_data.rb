class RetainRefundReconciliationData < ActiveRecord::Migration[8.1]
  def change
    add_column :payment_events, :refund_data, :json, null: false, default: {}
  end
end
