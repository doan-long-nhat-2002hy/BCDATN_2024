from flask import Flask, request, jsonify
import werkzeug
import os
from ultralytics import YOLOv10
from collections import Counter

app = Flask(__name__)
model_path = "best.pt"

@app.route('/upload', methods=['POST'])
def upload():
    if(request.method == "POST"):
        imagefile = request.files['image']
        filename = werkzeug.utils.secure_filename(imagefile.filename)
        #imagefile.save("./uploadedimages/" + filename)
        image_path = os.path.join("./uploadedimages", filename)
        imagefile.save(image_path)
        # tên ảnh được lưu vào biến nào ở trên, hãy giúp tôi print ra
        # khi huấn luyện bằng mô hình thì lấy filename hay lấy image_path
        try:
            model = YOLOv10(model_path)
            result = model(source=image_path, conf=0.15, save=True)
            boxes = result[0].boxes
            label_indices = boxes.cls
            names = result[0].names
            label_count = Counter(label_indices)
            most_common_label_index = label_count.most_common(1)[0][0]
            most_common_label_name = names[int(most_common_label_index)]
            print(most_common_label_name)
            # Trả về most_common_label_name dưới dạng JSON
            return jsonify({"most_common_label_name": most_common_label_name})
        except Exception as e:
            return jsonify({"error": str(e)}), 500
        # return jsonify({
        #     "message" : "Image Uploaded Successfully"
        # })

if(__name__ == "__main__"):
    app.run(debug=True, port=4000)
    
# đã truyền được ảnh từ flutter sang flask bằng phương thức POST, đã lưu được ảnh vào thư mục uploadedimages
# việc cần làm bây giờ là phải đọc ảnh từ thư mục uploadedimages và dự đoán ảnh đó trả lại kết quả cho flutter
