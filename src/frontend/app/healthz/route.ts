import { NextResponse } from 'next/server';

// GET /healthz - ヘルスチェックエンドポイント
export async function GET() {
  return NextResponse.json({ status: "ok" }, { status: 200 });
}
