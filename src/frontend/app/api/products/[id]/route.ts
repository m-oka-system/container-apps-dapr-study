import { NextRequest, NextResponse } from 'next/server';

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:5002';
const API_PRODUCTS_PATH = process.env.API_PRODUCTS_PATH || 'products';
const API_SECRET_KEY = process.env.API_SECRET_KEY;

const getApiHeaders = () => {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  if (API_SECRET_KEY) {
    headers['Authorization'] = `Bearer ${API_SECRET_KEY}`;
  }

  return headers;
};

// GET /api/products/[id] - 商品詳細取得
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params;

    const response = await fetch(`${API_BASE_URL}/${API_PRODUCTS_PATH}/${id}`, {
      method: 'GET',
      headers: getApiHeaders(),
    });

    if (!response.ok) {
      if (response.status === 404) {
        return NextResponse.json(
          { error: 'Product not found' },
          { status: 404 }
        );
      }
      throw new Error(`API request failed: ${response.status}`);
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Failed to fetch product:', error);
    return NextResponse.json(
      { error: 'Failed to fetch product' },
      { status: 500 }
    );
  }
}

// PUT /api/products/[id] - 商品更新
export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params;
    const body = await request.json();

    // バリデーション
    if (!body.name || !body.price) {
      return NextResponse.json(
        { error: 'Name and price are required' },
        { status: 400 }
      );
    }

    const response = await fetch(`${API_BASE_URL}/${API_PRODUCTS_PATH}/${id}`, {
      method: 'PUT',
      headers: getApiHeaders(),
      body: JSON.stringify({ ...body, id }),
    });

    if (!response.ok) {
      if (response.status === 404) {
        return NextResponse.json(
          { error: 'Product not found' },
          { status: 404 }
        );
      }
      if (response.status === 405) {
        return NextResponse.json(
          { error: 'Update method not supported by API' },
          { status: 405 }
        );
      }
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `API request failed: ${response.status}`);
    }

    const data = await response.json();
    return NextResponse.json(data);
  } catch (error) {
    console.error('Failed to update product:', error);
    return NextResponse.json(
      { error: error instanceof Error ? error.message : 'Failed to update product' },
      { status: 500 }
    );
  }
}

// DELETE /api/products/[id] - 商品削除
export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const { id } = params;

    const response = await fetch(`${API_BASE_URL}/${API_PRODUCTS_PATH}/${id}`, {
      method: 'DELETE',
      headers: getApiHeaders(),
    });

    if (!response.ok && response.status !== 204) {
      if (response.status === 404) {
        return NextResponse.json(
          { error: 'Product not found' },
          { status: 404 }
        );
      }
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `API request failed: ${response.status}`);
    }

    // 204 No Content または正常なレスポンス
    return new NextResponse(null, { status: 204 });
  } catch (error) {
    console.error('Failed to delete product:', error);
    return NextResponse.json(
      { error: 'Failed to delete product' },
      { status: 500 }
    );
  }
}
