"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { useForm } from "react-hook-form";
import * as z from "zod";
import { Button } from "@/components/ui/button";
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Product } from "@/types/product";

// フォームの入力値のバリデーションスキーマをzodで定義
const formSchema = z.object({
  name: z.string().min(1, { message: "商品名は必須です。" }),
  price: z.coerce // 文字列で入力されても数値に変換する
    .number({ invalid_type_error: "価格は数値で入力してください。" })
    .positive({ message: "価格は0より大きい値を入力してください。" }),
});

// ProductFormコンポーネントが受け取るpropsの型定義
interface ProductFormProps {
  product?: Product | null; // 編集対象の商品データ（新規の場合はnull）
  onSubmit: (values: z.infer<typeof formSchema>) => Promise<void>; // フォーム送信時の処理
  isSubmitting: boolean; // 送信処理中かどうか
}

export function ProductForm({ product, onSubmit, isSubmitting }: ProductFormProps) {
  // react-hook-formの初期化
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema), // zodスキーマでバリデーション
    defaultValues: {
      // 初期値: 編集時は商品データ、新規時は空文字と0
      name: product?.name || "",
      price: product?.price || 0,
    },
  });

  return (
    // shadcn/uiのFormコンポーネント
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
        {/* 商品名入力フィールド */}
        <FormField
          control={form.control}
          name="name"
          render={({ field }) => (
            <FormItem>
              <FormLabel>商品名</FormLabel>
              <FormControl>
                <Input placeholder="例: 高性能ノートパソコン" {...field} />
              </FormControl>
              <FormMessage /> {/* バリデーションエラーメッセージ表示 */}
            </FormItem>
          )}
        />
        {/* 価格入力フィールド */}
        <FormField
          control={form.control}
          name="price"
          render={({ field }) => (
            <FormItem>
              <FormLabel>価格</FormLabel>
              <FormControl>
                {/* type="number" を指定すると、数値以外の入力がある程度制限される */}
                <Input type="number" placeholder="例: 150000" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button type="submit" disabled={isSubmitting}>
          {isSubmitting ? "送信中..." : product ? "更新" : "登録"}
        </Button>
      </form>
    </Form>
  );
}
