-- Phase 7 partner model: Bedrock holds the code; the partner approves any way
-- out. A request the partner doesn't approve within 3 days opens anyway and the
-- partner is told, so a lost or controlling key holder can't trap anyone.
alter table public.approval_requests
    add column if not exists auto_released boolean not null default false;

create index if not exists approval_requests_open_idx
    on public.approval_requests (status, created_at);
