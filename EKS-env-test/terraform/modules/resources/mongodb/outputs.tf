output "mongodb_endpoint" {
    value = aws_docdb_cluster.docdb.endpoint
}

output "mongodb_reader_endpoint" {
     value = aws_docdb_cluster.docdb.reader_endpoint
}