def qbe_journal_add
  <<~XML
    <JournalEntryAddRq requestID="12345">
      <JournalEntryAdd>
        <TxnDate>2020-03-18</TxnDate>
        <RefNumber>S00009</RefNumber>
        <IsAdjustment>false</IsAdjustment>
        <JournalDebitLine>
          <TxnLineID>1</TxnLineID>
          <AccountRef>
              <FullName>NuRelm Commission Receivable</FullName>
          </AccountRef>
          <Amount>200.00</Amount>
          <Memo>Testing a journal entry here 1</Memo>
          <EntityRef>
            <FullName>My Customer</FullName>
          </EntityRef>
          <ClassRef>
            <FullName>Pittsburghtown</FullName>
          </ClassRef>
        </JournalDebitLine>
        <JournalCreditLine>
          <TxnLineID>2</TxnLineID>
          <AccountRef>
              <FullName>Fees</FullName>
          </AccountRef>
          <Amount>120.02</Amount>
          <Memo>Testing a journal entry here 2</Memo>
          <EntityRef>
            <FullName>My Customer credit!</FullName>
          </EntityRef>
          <ClassRef>
            <FullName>Pittsburghtown</FullName>
          </ClassRef>
        </JournalCreditLine>
        <JournalCreditLine>
          <TxnLineID>3</TxnLineID>
          <AccountRef>
              <FullName>Marketing Income</FullName>
          </AccountRef>
          <Amount>79.98</Amount>
          <Memo>Testing a journal entry here 3</Memo>
          <EntityRef>
            <FullName>My Customer credit!</FullName>
          </EntityRef>
          <ClassRef>
            <FullName>Pittsburghtown</FullName>
          </ClassRef>
        </JournalCreditLine>
      </JournalEntryAdd>
    </JournalEntryAddRq>
  XML
end

def qbe_journal_update
  <<~XML
    <JournalEntryModRq requestID="12345">
      <JournalEntryMod>
        <TxnID>999281771</TxnID>
        <EditSequence>102930910</EditSequence>
        <TxnDate>2020-03-18</TxnDate>
        <RefNumber>S00009</RefNumber>
        <IsAdjustment>true</IsAdjustment>
        <JournalDebitLine>
          <TxnLineID>1</TxnLineID>
          <AccountRef>
              <FullName>NuRelm Commission Receivable</FullName>
          </AccountRef>
          <Amount>200.00</Amount>
          <Memo>Testing a journal entry here 1</Memo>
          <EntityRef>
            <FullName>My Customer</FullName>
          </EntityRef>
          <ClassRef>
            <FullName>Pittsburghtown</FullName>
          </ClassRef>
        </JournalDebitLine>
        <JournalCreditLine>
          <TxnLineID>2</TxnLineID>
          <AccountRef>
              <FullName>Fees</FullName>
          </AccountRef>
          <Amount>120.02</Amount>
          <Memo>Testing a journal entry here 2</Memo>
          <EntityRef>
            <FullName>My Customer credit!</FullName>
          </EntityRef>
          <ClassRef>
            <FullName>Pittsburghtown</FullName>
          </ClassRef>
        </JournalCreditLine>
        <JournalCreditLine>
          <TxnLineID>3</TxnLineID>
          <AccountRef>
              <FullName>Marketing Income</FullName>
          </AccountRef>
          <Amount>79.98</Amount>
          <Memo>Testing a journal entry here 3</Memo>
          <EntityRef>
            <FullName>My Customer credit!</FullName>
          </EntityRef>
          <ClassRef>
            <FullName>Pittsburghtown</FullName>
          </ClassRef>
        </JournalCreditLine>
      </JournalEntryMod>
    </JournalEntryModRq>
  XML
end

def qbe_journal_search
  <<~XML
    <JournalEntryQueryRq requestID="12345">
      <RefNumber>S00009</RefNumber>
    </JournalEntryQueryRq>
  XML
end

def qbe_journal_delete
  <<~XML
    <TxnDelRq requestID="12345">
      <TxnDelType >JournalEntry</TxnDelType>
      <TxnID>999281771</TxnID>
    </TxnDelRq>
  XML
end
