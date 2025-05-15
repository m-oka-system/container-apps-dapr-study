"use client";

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Product } from "@/types/product"; // 商品の型定義 (後で作成)
import { Pencil, Trash2 } from "lucide-react";

// ProductTableコンポーネントが受け取るprops（引数）の型定義
interface ProductTableProps {
  products: Product[];
  onEdit: (product: Product) => void; // 編集ボタンクリック時の処理
  onDelete: (productId: string) => void; // 削除ボタンクリック時の処理
}

export function ProductTable({ products, onEdit, onDelete }: ProductTableProps) {
  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>ID</TableHead>
          <TableHead>商品名</TableHead>
          <TableHead>価格</TableHead>
          <TableHead className="text-right">操作</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {products.length > 0 ? (
          products.map((product) => (
            <TableRow key={product.id}>
              <TableCell className="font-medium">{product.id}</TableCell>
              <TableCell>{product.name}</TableCell>
              <TableCell>{product.price}</TableCell>
              <TableCell className="text-right">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => onEdit(product)}
                  className="mr-2"
                >
                  <Pencil className="mr-1 h-4 w-4" />
                  編集
                </Button>
                <Button
                  variant="destructive"
                  size="sm"
                  onClick={() => onDelete(product.id)}
                >
                  <Trash2 className="mr-1 h-4 w-4" />
                  削除
                </Button>
              </TableCell>
            </TableRow>
          ))
        ) : (
          <TableRow>
            <TableCell colSpan={4} className="text-center">
              商品がありません。
            </TableCell>
          </TableRow>
        )}
      </TableBody>
    </Table>
  );
}
