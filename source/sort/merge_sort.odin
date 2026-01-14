package sort

@(rodata)
MERGE_SORT_DUR: [MergeSortState]f32 = {}
MergeSortState :: enum {}
MergeSort :: struct {}
process_merge_sort :: proc(sort: ^Sort, algo: ^MergeSort) -> (is_completed: bool){
    is_completed = true
    return
}
draw_merge_sort :: proc(sort: ^Sort, algo: ^MergeSort){

}