"use client";

import { useEffect, useState, useCallback, useTransition } from "react";
import { Button } from "@/components/ui/button";
import { ProductTable } from "@/components/products/ProductTable";
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

// Server Actionsのインポート
import {
  getProducts,
  createProductFromObject,
  updateProduct,
  deleteProduct,
  type Product
} from "@/lib/actions/products";

// eslint-disable-next-line @typescript-eslint/no-unused-vars
const formSchema = z.object({
  name: z.string().min(1, { message: "商品名は必須です。" }),
  price: z.coerce
    .number({ invalid_type_error: "価格は数値で入力してください。" })
    .positive({ message: "価格は0より大きい値を入力してください。" }),
});

export default function ProductsPage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [isAlertOpen, setIsAlertOpen] = useState(false);
  const [deletingProductId, setDeletingProductId] = useState<string | null>(null);
  const { toast } = useToast();

  // useTransition for Server Actions
  const [isPending, startTransition] = useTransition();

  // Server Actionを使用して商品一覧を取得
  const fetchProducts = useCallback(async () => {
    setLoading(true);
    setError(null);

    const result = await getProducts();

    if (result.success && result.data) {
      setProducts(result.data);
    } else {
      const errorMessage = result.error || "商品の取得に失敗しました";
      setError(errorMessage);
      if (toast) {
        toast({
          title: "エラー",
          description: errorMessage,
          variant: "destructive"
        });
      }
    }
    setLoading(false);
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

  // Server Actionを使用して商品を削除
  const confirmDelete = async () => {
    if (!deletingProductId) return;

    startTransition(async () => {
      const result = await deleteProduct(deletingProductId);

      if (result.success) {
        if (toast) {
          toast({
            title: "削除成功",
            description: `商品ID「${deletingProductId}」を削除しました。`,
          });
        }
        // 商品一覧を再取得
        fetchProducts();
      } else {
        if (toast) {
          toast({
            title: "削除エラー",
            description: result.error || "商品の削除に失敗しました",
            variant: "destructive",
          });
        }
      }

      setIsAlertOpen(false);
      setDeletingProductId(null);
    });
  };

  // Server Actionを使用して商品を作成/更新
  const handleSubmit = async (values: z.infer<typeof formSchema>) => {
    startTransition(async () => {
      let result;

      if (editingProduct) {
        // 更新
        result = await updateProduct(editingProduct.id, {
          name: values.name,
          price: values.price,
        });
      } else {
        // 作成
        result = await createProductFromObject({
          name: values.name,
          price: values.price,
        });
      }

      if (result.success) {
        if (toast) {
          toast({
            title: editingProduct ? "更新成功" : "登録成功",
            description: `商品「${values.name}」が${editingProduct ? "更新" : "登録"}されました。`,
          });
        }
        setIsDialogOpen(false);
        // 商品一覧を再取得
        fetchProducts();
      } else {
        if (toast) {
          toast({
            title: "エラー",
            description: result.error || `${editingProduct ? "更新" : "登録"}に失敗しました`,
            variant: "destructive",
          });
        }
      }
    });
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
        <Button onClick={handleOpenNewDialog} disabled={isPending}>
          <PlusCircle className="mr-2 h-4 w-4" />
          新規商品追加
        </Button>
      </div>

      <ProductTable
        products={products}
        onEdit={handleEdit}
        onDelete={handleDelete}
      />

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
            isSubmitting={isPending}
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
            <AlertDialogCancel onClick={() => setDeletingProductId(null)} disabled={isPending}>
              キャンセル
            </AlertDialogCancel>
            <AlertDialogAction onClick={confirmDelete} disabled={isPending}>
              {isPending ? "削除中..." : "削除"}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
