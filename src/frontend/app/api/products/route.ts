import { NextRequest, NextResponse } from 'next/server';

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:5002';
const API_PRODUCTS_PATH = process.env.API_PRODUCTS_PATH || 'products';
const API_SECRET_KEY = process.env.API_SECRET_KEY;

// 共通のヘッダー設定
const getApiHeaders = () => {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  // APIキーが必要な場合
  if (API_SECRET_KEY) {
    headers['Authorization'] = `Bearer ${API_SECRET_KEY}`;
    // または headers['X-API-Key'] = API_SECRET_KEY;
  }

  return headers;
};

// GET /api/products - 商品一覧取得
export async function GET() {
  try {
    const response = await fetch(`${API_BASE_URL}/${API_PRODUCTS_PATH}`, {
      method: 'GET',
      headers: getApiHeaders(),
    });

    if (!response.ok) {
      throw new Error(`API request failed: ${response.status}`);
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Failed to fetch products:', error);
    return NextResponse.json(
      { error: 'Failed to fetch products' },
      { status: 500 }
    );
  }
}

// POST /api/products - 商品作成
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();

    // バリデーション
    if (!body.name || !body.price) {
      return NextResponse.json(
        { error: 'Name and price are required' },
        { status: 400 }
      );
    }

    const response = await fetch(`${API_BASE_URL}/${API_PRODUCTS_PATH}`, {
      method: 'POST',
      headers: getApiHeaders(),
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `API request failed: ${response.status}`);
    }

    const data = await response.json();
    return NextResponse.json(data, { status: 201 });
  } catch (error) {
    console.error('Failed to create product:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to create product' },
      { status: 500 }
    );
  }
}
