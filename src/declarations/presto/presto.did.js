export const idlFactory = ({ IDL }) => {
  const Time = IDL.Int;
  const EscrowEvent = IDL.Record({
    'needsApproval' : IDL.Bool,
    'assetID' : IDL.Text,
    'name' : IDL.Text,
    'sellerApproved' : IDL.Bool,
    'description' : IDL.Text,
    'isDeposit' : IDL.Bool,
    'lenderApproved' : IDL.Bool,
    'trusteeApproved' : IDL.Bool,
    'isTitleDocument' : IDL.Bool,
    'buyerApproved' : IDL.Bool,
    'datetime' : Time,
    'eventType' : IDL.Text,
  });
  const Chunk = IDL.Record({
    'content' : IDL.Vec(IDL.Nat8),
    'batch_name' : IDL.Text,
  });
  const Token = IDL.Principal;
  const DepositErr = IDL.Variant({
    'TransferFailure' : IDL.Null,
    'BalanceLow' : IDL.Null,
  });
  const DepositReceipt = IDL.Variant({ 'Ok' : IDL.Nat, 'Err' : DepositErr });
  const Principal = IDL.Principal;
  const EscrowType = IDL.Record({
    'escrowEvents' : IDL.Vec(EscrowEvent),
    'trustee' : IDL.Opt(Principal),
    'seller' : IDL.Opt(Principal),
    'lender' : IDL.Opt(Principal),
    'buyer' : IDL.Opt(Principal),
    'amount' : IDL.Nat64,
  });
  const HeaderField = IDL.Tuple(IDL.Text, IDL.Text);
  const HttpRequest = IDL.Record({
    'url' : IDL.Text,
    'method' : IDL.Text,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
  });
  const HttpResponse = IDL.Record({
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
    'status_code' : IDL.Nat16,
  });
  const WithdrawErr = IDL.Variant({
    'TransferFailure' : IDL.Null,
    'BalanceLow' : IDL.Null,
  });
  const WithdrawReceipt = IDL.Variant({ 'Ok' : IDL.Nat, 'Err' : WithdrawErr });
  const File = IDL.Record({
    'content' : IDL.Vec(IDL.Nat8),
    'assetID' : IDL.Text,
    'content_type' : IDL.Text,
    'contentLength' : IDL.Nat,
  });
  const Presto = IDL.Service({
    'addEscrowEvent' : IDL.Func([IDL.Text, EscrowEvent], [], ['oneway']),
    'approveEscrowEvent' : IDL.Func(
        [IDL.Text, IDL.Nat, IDL.Principal],
        [EscrowEvent],
        [],
      ),
    'createEscrow' : IDL.Func([IDL.Principal, IDL.Nat], [IDL.Text], []),
    'create_chunk' : IDL.Func(
        [Chunk],
        [IDL.Record({ 'chunk_id' : IDL.Nat })],
        [],
      ),
    'deposit' : IDL.Func([Token], [DepositReceipt], []),
    'getAsset' : IDL.Func([IDL.Text], [IDL.Opt(IDL.Vec(IDL.Nat8))], []),
    'getBalanceForUser' : IDL.Func([], [IDL.Nat], []),
    'getDepositAddress' : IDL.Func([], [IDL.Vec(IDL.Nat8)], []),
    'getDepositAddressString' : IDL.Func([], [IDL.Opt(IDL.Text)], []),
    'getDocumentID' : IDL.Func([], [IDL.Text], []),
    'getEscrowState' : IDL.Func([IDL.Text], [EscrowType], []),
    'getEscrowsForUser' : IDL.Func([IDL.Principal], [IDL.Vec(IDL.Text)], []),
    'greet' : IDL.Func([IDL.Text], [IDL.Text], []),
    'http_request' : IDL.Func([HttpRequest], [HttpResponse], ['query']),
    'releaseToSeller' : IDL.Func([IDL.Text], [WithdrawReceipt], []),
    'setBuyer' : IDL.Func([IDL.Text, IDL.Principal], [], ['oneway']),
    'setEscrowUnlockTime' : IDL.Func([IDL.Text, Time], [], ['oneway']),
    'setSeller' : IDL.Func([IDL.Text, IDL.Principal], [], ['oneway']),
    'upload_file' : IDL.Func([File], [], ['oneway']),
    'withdraw' : IDL.Func(
        [Token, IDL.Nat, IDL.Principal],
        [WithdrawReceipt],
        [],
      ),
  });
  return Presto;
};
export const init = ({ IDL }) => { return []; };
