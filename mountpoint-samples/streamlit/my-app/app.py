import streamlit as st
import os

uploaded_file = st.file_uploader("파일을 선택해주세요", type=['jpeg', 'png'])

if uploaded_file is not None:
    save_path = './uploads'
    if not os.path.exists(save_path):
        os.makedirs(save_path)
    
    file_path = os.path.join(save_path, uploaded_file.name)
    
    with open(file_path, "wb") as f:
        f.write(uploaded_file.getbuffer())
    
    st.success(f"'{uploaded_file.name}' 파일이 성공적으로 저장되었습니다.")
