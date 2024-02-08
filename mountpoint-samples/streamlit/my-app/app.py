import streamlit as st
import os

st.title('Mountpoint for S3 Demo')
path = '/mountpoint-s3/'

uploaded_file = st.file_uploader("Select your image or video file.", type=['jpg', 'jpeg', 'png', 'mp4'])

if uploaded_file is not None:
    file_type = uploaded_file.type.split('/')[0]  
    save_path = os.path.join(path, file_type)  
    
    if not os.path.exists(save_path):
        os.makedirs(save_path)
    
    file_path = os.path.join(save_path, uploaded_file.name)
    with open(file_path, "wb") as f:
        f.write(uploaded_file.getbuffer())
    st.success(f"'{uploaded_file.name}' has been uploaded successfully.")


def list_files(startpath):
    files_list = []
    for root, dirs, files in os.walk(startpath):
        for f in files:
            file_ext = f.split('.')[-1] 
            files_list.append({"path": os.path.join(root, f), "name": f, "type": file_ext})
    return files_list

if st.sidebar.button('Refresh'):
    st.rerun()
file_list = list_files(path)
st.sidebar.header("List of files")

for file_info in file_list:
    file_name = file_info['name']
    file_path = file_info['path']
    file_type = file_info['type']
    
    col1, col2, col3 = st.sidebar.columns([3, 1, 1])
    col1.write(file_name)
    
    if col2.button('Remove', key=f"delete_{file_path}"):
        os.remove(file_path)
        st.rerun()
    
    if col3.button('Show', key=f"show_{file_path}"):
        if file_type in ['jpg', 'jpeg', 'png']:
            st.image(file_path, caption=file_name)
            print(file_path)
        elif file_type == 'mp4':
            st.video(file_path)
