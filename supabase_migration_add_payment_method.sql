-- Add payment_method column to transactions table
-- This migration adds the payment_method column to store payment method information

ALTER TABLE transactions
ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'cash';

-- Add a comment to document the column
COMMENT ON COLUMN transactions.payment_method IS 'Payment method used for the transaction (credit_card, debit_card, cash, bank_transfer, digital_wallet, other)';

-- Update existing rows to have a default value if they are NULL
UPDATE transactions
SET payment_method = 'cash'
WHERE payment_method IS NULL;
