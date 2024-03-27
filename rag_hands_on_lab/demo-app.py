from basic import get_conversation
import streamlit as st
from uploader import upload_and_process_file  # 추가된 부분

uploaded_file = st.file_uploader("파일을 업로드하세요", type=["pdf"])
prompt = st.text_input("프롬프트를 입력하세요.")
search_type = st.radio("Search Type", ["Basic", "Basic-RAG", "Hybrid-RAG", "Advanced-RAG"])

chat_box = st.empty()

if 'conversation' not in st.session_state or 'stream_handler' not in st.session_state:
    st.session_state.conversation, st.session_state.stream_handler = get_conversation(chat_box)

def search_documents(search_type: str, prompt: str):
    if search_type == "Basic":
        st.session_state.stream_handler.reset_accumulated_text()
        st.session_state.conversation.predict(input=prompt)
    elif search_type == "Basic-RAG":
        st.write(f"문서 기본 검색: {prompt}")
    elif search_type == "Hybrid-RAG":
        st.write(f"하이브리드 검색: {prompt}")
    elif search_type == "Advanced-RAG":
        st.write(f"고급 검색: {prompt}")

if st.button("검색"):
    search_documents(search_type, prompt)

if uploaded_file is not None:
    print("File uploaded:", uploaded_file.name)
    upload_and_process_file(uploaded_file)
else:
    print("No file uploaded.")

if uploaded_file is not None:
    res = upload_and_process_file(uploaded_file)
    if res:
        st.success("파일이 성공적으로 처리됐습니다.")
    else:
        st.error("파일 처리 중 오류가 발생했습니다.")
