import type { Principal } from '@dfinity/principal';
import type { ActorMethod } from '@dfinity/agent';

export interface Chunk { 'content' : Array<number>, 'batch_name' : string }
export type DepositErr = { 'TransferFailure' : null } |
  { 'BalanceLow' : null };
export type DepositReceipt = { 'Ok' : bigint } |
  { 'Err' : DepositErr };
export interface EscrowEvent {
  'needsApproval' : boolean,
  'assetID' : string,
  'name' : string,
  'sellerApproved' : boolean,
  'description' : string,
  'isDeposit' : boolean,
  'lenderApproved' : boolean,
  'trusteeApproved' : boolean,
  'isTitleDocument' : boolean,
  'buyerApproved' : boolean,
  'datetime' : Time,
  'eventType' : string,
}
export interface EscrowType {
  'escrowEvents' : Array<EscrowEvent>,
  'trustee' : [] | [Principal],
  'seller' : [] | [Principal],
  'lender' : [] | [Principal],
  'buyer' : [] | [Principal],
  'amount' : bigint,
}
export interface File {
  'content' : Array<number>,
  'assetID' : string,
  'content_type' : string,
  'contentLength' : bigint,
}
export type HeaderField = [string, string];
export interface HttpRequest {
  'url' : string,
  'method' : string,
  'body' : Array<number>,
  'headers' : Array<HeaderField>,
}
export interface HttpResponse {
  'body' : Array<number>,
  'headers' : Array<HeaderField>,
  'status_code' : number,
}
export interface Presto {
  'addEscrowEvent' : ActorMethod<[string, EscrowEvent], undefined>,
  'approveEscrowEvent' : ActorMethod<[string, bigint, Principal], EscrowEvent>,
  'createEscrow' : ActorMethod<[Principal, bigint], string>,
  'create_chunk' : ActorMethod<[Chunk], { 'chunk_id' : bigint }>,
  'deposit' : ActorMethod<[Token], DepositReceipt>,
  'getAsset' : ActorMethod<[string], [] | [Array<number>]>,
  'getBalanceForUser' : ActorMethod<[], bigint>,
  'getDepositAddress' : ActorMethod<[], Array<number>>,
  'getDepositAddressString' : ActorMethod<[], [] | [string]>,
  'getDocumentID' : ActorMethod<[], string>,
  'getEscrowState' : ActorMethod<[string], EscrowType>,
  'getEscrowsForUser' : ActorMethod<[Principal], Array<string>>,
  'greet' : ActorMethod<[string], string>,
  'http_request' : ActorMethod<[HttpRequest], HttpResponse>,
  'releaseToSeller' : ActorMethod<[string], WithdrawReceipt>,
  'setBuyer' : ActorMethod<[string, Principal], undefined>,
  'setEscrowUnlockTime' : ActorMethod<[string, Time], undefined>,
  'setSeller' : ActorMethod<[string, Principal], undefined>,
  'upload_file' : ActorMethod<[File], undefined>,
  'withdraw' : ActorMethod<[Token, bigint, Principal], WithdrawReceipt>,
}
export type Principal = Principal;
export type Time = bigint;
export type Token = Principal;
export type WithdrawErr = { 'TransferFailure' : null } |
  { 'BalanceLow' : null };
export type WithdrawReceipt = { 'Ok' : bigint } |
  { 'Err' : WithdrawErr };
export interface _SERVICE extends Presto {}
