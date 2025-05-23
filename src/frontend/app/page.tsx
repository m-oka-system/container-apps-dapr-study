"use client";

import { useEffect, useState, useCallback } from "react";
import { Button } from "@/components/ui/button";
import { ProductTable } from "@/components/products/ProductTable";
import { Product } from "@/types/product";
import { PlusCircle } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { ProductForm } from "@/components/products/ProductForm";
import { useToast } from "@/hooks/use-toast";
import * as z from "zod";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const formSchema = z.object({
  name: z.string().min(1, { message: "商品名は必須です。" }),
  price: z.coerce
    .number({ invalid_type_error: "価格は数値で入力してください。" })
    .positive({ message: "価格は0より大きい値を入力してください。" }),
});

// APIに送信するデータの型
interface ProductPayload {
  id?: string;
  name: string;
  price: number;
}

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [isAlertOpen, setIsAlertOpen] = useState(false);
  const [deletingProductId, setDeletingProductId] = useState<string | null>(null);
  const { toast } = useToast();

  // Next.js の API Route 経由で商品一覧を取得
  const fetchProducts = useCallback(async () => {
    setLoading(true);
    try {
      const response = await fetch('/api/products');
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const data = await response.json();
      setProducts(data);
    } catch (e) {
      const errorMessage = e instanceof Error ? e.message : "不明なエラーが発生しました";
      setError(errorMessage);
      if (toast) {
        toast({
          title: "エラー",
          description: `商品の取得に失敗しました: ${errorMessage}`,
          variant: "destructive"
        });
      }
      console.error("Failed to fetch products:", e);
    } finally {
      setLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    fetchProducts();
  }, [fetchProducts]);

  const handleOpenNewDialog = () => {
    setEditingProduct(null);
    setIsDialogOpen(true);
  };

  const handleEdit = (product: Product) => {
    setEditingProduct(product);
    setIsDialogOpen(true);
  };

  const handleDelete = (productId: string) => {
    setDeletingProductId(productId);
    setIsAlertOpen(true);
  };

  // Next.js の API Route 経由で商品を削除
  const confirmDelete = async () => {
    if (!deletingProductId) return;
    setIsSubmitting(true);
    try {
      const response = await fetch(`/api/products/${deletingProductId}`, {
        method: "DELETE",
      });

      if (!response.ok) {
        if (response.status === 404) {
          throw new Error("商品が見つかりません");
        }
        const errorData = await response.json().catch(() => ({ error: "不明なサーバーエラー" }));
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      if (toast) {
        toast({
          title: "削除成功",
          description: `商品ID「${deletingProductId}」を削除しました。`,
        });
      }
      fetchProducts();
    } catch (e) {
      const errorMessage = e instanceof Error ? e.message : "不明なエラーが発生しました";
      if (toast) {
        toast({
          title: "削除エラー",
          description: `商品の削除に失敗しました: ${errorMessage}`,
          variant: "destructive",
        });
      }
      console.error("Failed to delete product:", e);
    } finally {
      setIsSubmitting(false);
      setIsAlertOpen(false);
      setDeletingProductId(null);
    }
  };

  // Next.jsのAPI Route経由で商品を作成/更新
  const handleSubmit = async (values: z.infer<typeof formSchema>) => {
    setIsSubmitting(true);
    let url: string;
    let method: string;
    let payload: ProductPayload;

    if (editingProduct) {
      method = "PUT";
      url = `/api/products/${editingProduct.id}`;
      payload = { id: editingProduct.id, name: values.name, price: values.price };
    } else {
      method = "POST";
      url = "/api/products";
      payload = { name: values.name, price: values.price };
    }

    try {
      const response = await fetch(url, {
        method: method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (!response.ok) {
        if (response.status === 404) {
          throw new Error("商品が見つかりません");
        }
        if (response.status === 405) {
          throw new Error("APIが編集処理をサポートしていません");
        }
        const errorData = await response.json().catch(() => ({ error: "不明なサーバーエラー" }));
        throw new Error(errorData.error || `HTTP error! status: ${response.status}`);
      }

      if (toast) {
        toast({
          title: editingProduct ? "更新成功" : "登録成功",
          description: `商品「${values.name}」が${editingProduct ? "更新" : "登録"}されました。`,
        });
      }
      setIsDialogOpen(false);
      fetchProducts();
    } catch (e) {
      const errorMessage = e instanceof Error ? e.message : "不明なエラーが発生しました";
      if (toast) {
        toast({
          title: "エラー",
          description: `${editingProduct ? "更新" : "登録"}に失敗しました: ${errorMessage}`,
          variant: "destructive",
        });
      }
      console.error("Failed to submit product:", e);
    } finally {
      setIsSubmitting(false);
    }
  };

  if (loading && !isDialogOpen && !isAlertOpen) {
    return <div className="container mx-auto p-4">ローディング中...</div>;
  }

  if (error && !isDialogOpen && !isAlertOpen) {
    return <div className="container mx-auto p-4">エラー: {error}</div>;
  }

  return (
    <div className="container mx-auto p-4">
      <div className="flex justify-between items-center mb-4">
        <h1 className="text-2xl font-bold">商品一覧</h1>
        <Button onClick={handleOpenNewDialog}>
          <PlusCircle className="mr-2 h-4 w-4" />
          新規商品追加
        </Button>
      </div>

      <ProductTable products={products} onEdit={handleEdit} onDelete={handleDelete} />

      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="sm:max-w-[425px]">
          <DialogHeader>
            <DialogTitle>{editingProduct ? "商品を編集" : "新しい商品を追加"}</DialogTitle>
            <DialogDescription>
              {editingProduct ? "商品の詳細を編集します。" : "新しい商品の情報を入力してください。"}
            </DialogDescription>
          </DialogHeader>
          <ProductForm
            product={editingProduct}
            onSubmit={handleSubmit}
            isSubmitting={isSubmitting}
          />
        </DialogContent>
      </Dialog>

      <AlertDialog open={isAlertOpen} onOpenChange={setIsAlertOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>本当に削除しますか？</AlertDialogTitle>
            <AlertDialogDescription>
              この操作は元に戻せません。商品ID「{deletingProductId}」を完全に削除します。
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel onClick={() => setDeletingProductId(null)}>キャンセル</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} disabled={isSubmitting}>
              {isSubmitting ? "削除中..." : "削除"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
