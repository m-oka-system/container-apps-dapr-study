from flask import Flask, Response, request, jsonify
from flask_cors import CORS
import json
import uuid
from dapr.clients import DaprClient
import traceback

app = Flask(__name__)
CORS(app)
app.config['JSON_AS_ASCII'] = False

# Daprのステートストア名 (Daprコンポーネントファイルで定義する名前と一致させる)
# STATE_STORE_NAME = "blob-store"
STATE_STORE_NAME = "product-store"

# GET /healthz - ヘルスチェックエンドポイント
@app.route('/healthz', methods=['GET'])
def healthz():
    return jsonify({"status": "ok"}), 200

@app.route('/hello', methods=['GET'])
def hello_world():
    print("---- /hello endpoint CALLED ----", flush=True)
    return "Hello, Dapr!"

@app.route('/products', methods=['POST'])
def create_product():
    """新しい商品を作成し、Daprステートストアに保存します。"""
    try:
        data = request.get_json()
        if not data or 'name' not in data or 'price' not in data:
            return jsonify({"error": "Missing name or price in request body"}), 400

        product_id = str(uuid.uuid4())
        new_product = {
            "id": product_id,
            "name": data['name'],
            "price": data['price']
        }

        with DaprClient() as d:
            d.save_state(store_name=STATE_STORE_NAME, key=product_id, value=json.dumps(new_product))

        return Response(json.dumps(new_product, ensure_ascii=False), mimetype='application/json; charset=utf-8', status=201)

    except Exception as e:
        return Response(json.dumps({"error": "Failed to create product"}, ensure_ascii=False), mimetype='application/json; charset=utf-8', status=500)

@app.route('/products/<product_id>', methods=['GET'])
def get_product_by_id(product_id):
    """指定されたIDの商品をDaprステートストアから取得します。"""
    try:
        with DaprClient() as d:
            state = d.get_state(store_name=STATE_STORE_NAME, key=product_id)

            if state.data:
                product = json.loads(state.data.decode('utf-8'))
                return Response(json.dumps(product, ensure_ascii=False), mimetype='application/json; charset=utf-8')
            else:
                return Response(json.dumps({"error": "Product not found"}, ensure_ascii=False), mimetype='application/json; charset=utf-8', status=404)

    except Exception as e:
        return Response(json.dumps({"error": f"Failed to get product {product_id}"}, ensure_ascii=False), mimetype='application/json; charset=utf-8', status=500)

@app.route('/products', methods=['GET'])
def get_all_products():
    """Daprステートストアから全ての商品を取得します。"""
    try:
        with DaprClient() as d:
            query_body = {
                "query": "SELECT * FROM c"
            }
            res = d.query_state(
                store_name=STATE_STORE_NAME,
                query=json.dumps(query_body),
            )

            products = []
            if res.results:
                for item in res.results:
                    product = None
                    if hasattr(item, 'value') and item.value is not None:
                        try:
                            product_data_bytes = item.value
                            if isinstance(product_data_bytes, str):
                                product_data_bytes = product_data_bytes.encode('utf-8')

                            if isinstance(product_data_bytes, bytes):
                                product_data_str = product_data_bytes.decode('utf-8')
                                product = json.loads(product_data_str)
                        except Exception as e_value:
                            product = None

                    if product:
                        products.append(product)

            return Response(json.dumps(products, ensure_ascii=False), mimetype='application/json; charset=utf-8')

    except Exception as e:
        traceback.print_exc()
        return Response(json.dumps({"error": "Failed to get all products"}, ensure_ascii=False), mimetype='application/json; charset=utf-8', status=500)

@app.route('/products/<product_id>', methods=['DELETE'])
def delete_product(product_id):
    """指定されたIDの商品をDaprステートストアから削除します。"""
    try:
        with DaprClient() as d:
            state = d.get_state(store_name=STATE_STORE_NAME, key=product_id)
            if not state.data:
                return Response(json.dumps({"error": "Product not found"}, ensure_ascii=False), mimetype='application/json; charset=utf-8', status=404)

            d.delete_state(store_name=STATE_STORE_NAME, key=product_id)
            return '', 204

    except Exception as e:
        return Response(json.dumps({"error": f"Failed to delete product {product_id}"}, ensure_ascii=False), mimetype='application/json; charset=utf-8', status=500)

@app.route('/products/<product_id>', methods=['PUT'])
def update_product(product_id):
    """指定されたIDの商品をDaprステートストアで更新します。"""
    try:
        data = request.get_json()
        if not data or 'name' not in data or 'price' not in data:
            return jsonify({"error": "Missing name or price in request body"}), 400

        with DaprClient() as d:
            # 更新前に商品が存在するか確認 (任意ですが、存在しない商品を更新しようとした場合のエラーハンドリングとして有効)
            state = d.get_state(store_name=STATE_STORE_NAME, key=product_id)
            if not state.data:
                return Response(json.dumps({"error": "Product not found"}, ensure_ascii=False), mimetype='application/json; charset=utf-8', status=404)

            updated_product = {
                "id": product_id, # URLから取得したIDを使用
                "name": data['name'],
                "price": data['price']
            }
            d.save_state(store_name=STATE_STORE_NAME, key=product_id, value=json.dumps(updated_product))

            return Response(json.dumps(updated_product, ensure_ascii=False), mimetype='application/json; charset=utf-8', status=200)

    except Exception as e:
        traceback.print_exc()
        return Response(json.dumps({"error": f"Failed to update product {product_id}"}, ensure_ascii=False), mimetype='application/json; charset=utf-8', status=500)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5002)
