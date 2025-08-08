'use server';

import { revalidatePath } from 'next/cache';

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:5002';
const API_PRODUCTS_PATH = process.env.API_PRODUCTS_PATH || 'products';
const API_SECRET_KEY = process.env.API_SECRET_KEY;

// Product IDのサニタイズ関数
function sanitizeProductId(id: string): string {
  // 例: 英数字、ハイフン、アンダースコアのみ許可（必要に応じてUUIDや数値のみなどに変更）
  if (/^[a-zA-Z0-9_-]+$/.test(id)) {
    return id;
  }
  throw new Error('不正な商品IDです');
}

// 共通のヘッダー設定
const getApiHeaders = () => {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };

  if (API_SECRET_KEY) {
    headers['Authorization'] = `Bearer ${API_SECRET_KEY}`;
  }

  return headers;
};

// 戻り値の型定義
type ActionResult<T> = {
  success: boolean;
  data?: T;
  error?: string;
};

export interface Product {
  id: string;
  name: string;
  price: number;
}

// 商品一覧取得
export async function getProducts(): Promise<ActionResult<Product[]>> {
  try {
    const response = await fetch(`${API_BASE_URL}/${API_PRODUCTS_PATH}`, {
      method: 'GET',
      headers: getApiHeaders(),
      cache: 'no-store', // 常に最新データを取得
    });

    if (!response.ok) {
      throw new Error(`API request failed: ${response.status}`);
    }

    const data = await response.json();
    return { success: true, data };
  } catch (error) {
    console.error('Failed to fetch products:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to fetch products'
    };
  }
}

// 商品作成
export async function createProduct(formData: FormData): Promise<ActionResult<Product>> {
  try {
    const name = formData.get('name') as string;
    const price = parseFloat(formData.get('price') as string);

    // バリデーション
    if (!name || !price || price <= 0) {
      return {
        success: false,
        error: '商品名と正の価格は必須です。'
      };
    }

    const response = await fetch(`${API_BASE_URL}/${API_PRODUCTS_PATH}`, {
      method: 'POST',
      headers: getApiHeaders(),
      body: JSON.stringify({ name, price }),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `API request failed: ${response.status}`);
    }

    const data = await response.json();

    // キャッシュを再検証
    revalidatePath('/products');

    return { success: true, data };
  } catch (error) {
    console.error('Failed to create product:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to create product'
    };
  }
}

// オブジェクト形式の商品作成（フォーム以外からの呼び出し用）
export async function createProductFromObject(product: { name: string; price: number }): Promise<ActionResult<Product>> {
  try {
    // バリデーション
    if (!product.name || !product.price || product.price <= 0) {
      return {
        success: false,
        error: '商品名と正の価格は必須です。'
      };
    }

    const response = await fetch(`${API_BASE_URL}/${API_PRODUCTS_PATH}`, {
      method: 'POST',
      headers: getApiHeaders(),
      body: JSON.stringify(product),
    });

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `API request failed: ${response.status}`);
    }

    const data = await response.json();

    // キャッシュを再検証
    revalidatePath('/products');

    return { success: true, data };
  } catch (error) {
    console.error('Failed to create product:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to create product'
    };
  }
}

// 商品更新
export async function updateProduct(id: string, product: { name: string; price: number }): Promise<ActionResult<Product>> {
  try {
    // バリデーション
    if (!product.name || !product.price || product.price <= 0) {
      return {
        success: false,
        error: '商品名と正の価格は必須です。'
      };
    }

    let safeId: string;
    try {
      safeId = sanitizeProductId(id);
    } catch (e) {
      return {
        success: false,
        error: e instanceof Error ? e.message : '不正な商品IDです'
      };
    }

    const response = await fetch(`${API_BASE_URL}/${API_PRODUCTS_PATH}/${safeId}`, {
      method: 'PUT',
      headers: getApiHeaders(),
      body: JSON.stringify({ ...product, id: safeId }),
    });

    if (!response.ok) {
      if (response.status === 404) {
        return { success: false, error: '商品が見つかりません' };
      }
      if (response.status === 405) {
        return { success: false, error: 'APIが更新処理をサポートしていません' };
      }
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `API request failed: ${response.status}`);
    }

    const data = await response.json();

    // キャッシュを再検証
    revalidatePath('/products');

    return { success: true, data };
  } catch (error) {
    console.error('Failed to update product:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to update product'
    };
  }
}

// 商品削除
export async function deleteProduct(id: string): Promise<ActionResult<void>> {
  try {
    let safeId: string;
    try {
      safeId = sanitizeProductId(id);
    } catch (e) {
      return {
        success: false,
        error: e instanceof Error ? e.message : '不正な商品IDです'
      };
    }

    const response = await fetch(`${API_BASE_URL}/${API_PRODUCTS_PATH}/${safeId}`, {
      method: 'DELETE',
      headers: getApiHeaders(),
    });

    if (!response.ok && response.status !== 204) {
      if (response.status === 404) {
        return { success: false, error: '商品が見つかりません' };
      }
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.message || `API request failed: ${response.status}`);
    }

    // キャッシュを再検証
    revalidatePath('/products');

    return { success: true };
  } catch (error) {
    console.error('Failed to delete product:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to delete product'
    };
  }
}
