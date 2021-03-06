globalVariables(c("e", "."))

`%||%` <- function(x, y) {
  if (!is.null(x)) x else y
}

.assign_axis <- function(x){
  x$mapping$include_x <- FALSE
  cl <- x$mapping$x_class
  if(cl == "character" || cl == "factor"){
    x$opts$xAxis <- list(list(data = unique(x$data[[x$mapping$x]]), type = "category", boundaryGap = TRUE))
  } else if(cl == "POSIXct" || cl == "POSIXlt" || cl == "Date") {
    x$opts$xAxis <- list(list(data = unique(x$data[[x$mapping$x]]), type = "time", boundaryGap = TRUE))
  } else {
    x$data <- x$data %>% 
      dplyr::arrange_(x$mapping$x)
    x$mapping$include_x <- TRUE
    x$opts$xAxis <- list(list(type = "value"))
  }
  x
}

.rm_axis <- function(e, rm.x, axis){
  if(isTRUE(rm.x)){
    axis <- .r2axis(axis)
    e$x$opts[[axis]] <- NULL
  }
  e
}

.build_data <- function(e, ...){
  e$x$data %>% 
    dplyr::select_(...) -> data
  
  apply(unname(data), 1, function(x){
    list(value = unlist(x))
  }) 
    
}

.add_bind <- function(e, l, bind){
  e$x$data %>% 
    dplyr::select_(bind) %>% unname() %>% unlist() -> bind
  
  for(i in 1:length(l)){
    l[[i]]$name <- bind[i]
  }
  l
}

.build_data_p <- function(data, ..., names = NULL, vector = FALSE){
  data %>% 
    dplyr::select_(...) %>% 
    purrr::set_names(names) -> data
  
  if(isTRUE(vector))
    unlist(data)
  else
    apply(data, 1, as.list)
}

.build_sankey_nodes <- function(data, source, target){
  
  nodes <- c(
    unlist(
      dplyr::select_(data, source)
    ),
    unlist(
      dplyr::select_(data, target)
    )
  )
  
  nodes <- data.frame(
    name = unique(nodes),
    stringsAsFactors = FALSE
  )
  
  apply(nodes, 1, as.list)
  
  
}

.build_sankey_edges <- function(data, source, target, values){
  data %>%
    dplyr::select(!!source, !!target, !!values) -> edges
  
  names(edges) <- c("source", "target", "value")
  
  apply(edges, 1, as.list)
}

.build_graph_nodes <- function(nodes, names, value, symbolSize, category){
  
  nodes %>%
    dplyr::select(
      !!names,
      !!value,
      !!symbolSize,
      !!category
    ) -> data
  
  names(data) <- c("name", "value", "symbolSize", "category")[1:ncol(data)]
  
  data$id <- as.numeric(as.factor(data$name)) - 1
  
  data %>% 
    dplyr::arrange_("id") -> data
  
  x <- apply(data, 1, as.list)
  
  for(i in 1:length(x)){
    x[[i]]$symbolSize <- as.numeric(paste(x[[i]]$symbolSize))
    x[[i]]$value <- as.numeric(paste(x[[i]]$value))
    x[[i]]$id <- as.numeric(x[[i]]$id)
  }
  x
}

.build_graph_nodes_no_cat <- function(nodes, names, value, symbolSize){
  
  nodes %>%
    dplyr::select(
      !!names,
      !!value,
      !!symbolSize
    ) -> data
  
  names(data) <- c("name", "value", "symbolSize")[1:ncol(data)]
  
  data$id <- as.numeric(as.factor(data$name)) - 1
  
  data %>% 
    dplyr::arrange_("id") -> data
  
  x <- apply(data, 1, as.list)
  
  for(i in 1:length(x)){
    x[[i]]$symbolSize <- as.numeric(paste(x[[i]]$symbolSize))
    x[[i]]$value <- as.numeric(paste(x[[i]]$value))
    x[[i]]$id <- as.numeric(x[[i]]$id)
  }
  x
}

.build_graph_edges <- function(edges, source, target){
  
  edges %>%
    dplyr::select(
      !!source,
      !!target
    ) -> data
  
  names(data) <- c("source", "target")
  
  data$id <- as.character(1:nrow(data) - 1)
  data$source <- as.numeric(as.factor(data$source)) - 1
  data$target <- as.numeric(as.factor(data$target)) - 1
  
  apply(data, 1, as.list) -> x
  for(i in 1:length(x)){
    x[[i]]$source <- as.numeric(paste(x[[i]]$source))
    x[[i]]$target <- as.numeric(paste(x[[i]]$target))
    x[[i]]$id <- as.numeric(x[[i]]$id)
  }
  x
}

.build_graph_category <- function(nodes, cat){
  nodes %>%
    dplyr::select(
      name = !!cat
    ) %>% 
    unique() -> data
  
  apply(data, 1, as.list) -> x
  names(x) <- NULL
  x
}

.graph_cat_legend <- function(e){
  e$x$data[[e$x$mapping$x]]
}

.build_boxplot <- function(data, serie){
  data %>%
    dplyr::select(
      !!serie
    ) %>%  
    unname() %>% 
    unlist() -> x
  
  boxplot.stats(x)$stats
}

.get_outliers <- function(data, serie){
  data %>%
    dplyr::select(
      !!serie
    ) %>%  
    unname() %>% 
    unlist() -> x
  
  boxplot.stats(x)$out
}

.build_outliers <- function(e, out){
  x <- length(e$x$opts$series[[1]]$data) - 1
  x <- rep(x, length(out))
  matrix <- cbind(x, out)
  apply(unname(matrix), 1, as.list)
}

.add_outliers <- function(e, serie){
  
  outliers <- .get_outliers(e$x$data, serie)
  outliers <- .build_outliers(e, outliers)
  
  scatter <- list(
    type = "scatter",
    data = outliers
  )
  
  if(length(e$x$opts$series) == 2)
    e$x$opts$series[[2]]$data <- append(e$x$opts$series[[2]]$data, outliers)
  else 
    e$x$opts$series <- append(e$x$opts$series, list(scatter))
  
  e
}

.build_tree <- function(e, parent, child){
  e$x$data %>%
    dplyr::select(
      !!parent,
      !!child
    ) -> df
  
  .tree_that(df)
}

.tree_that <- function(df){
  tree <- data.tree::FromDataFrameNetwork(df)
  data.tree::ToListExplicit(tree, unname = TRUE)
}

.build_sun <- function(e, parent, child, value){
  e$x$data %>%
    dplyr::select_(
      parent,
      name = child,
      value
    ) %>% 
    dplyr::group_by(parent) %>% 
    tidyr::nest() %>% 
    purrr::set_names(c("name", "children")) %>% 
    jsonlite::toJSON(., auto_unbox = TRUE, pretty = FALSE)
}

.build_river <- function(e, serie, label){
  
  x <- .get_data(e, e$x$mapping$x)
  label <- rep(label, length(x))
  
  e$x$data %>%
    dplyr::select_(serie) -> data
  
  data <- cbind(x, data, label)
  
  apply(unname(data), 1, as.list)
}

.get_class <- function(e, serie){
  class(.get_data(e, serie))
}

.get_type <- function(e, serie){
  cl <- .get_class(e, serie)
  
  if(cl == "character" || cl == "factor"){
    "category"
  } else if(cl == "POSIXct" || cl == "POSIXlt" || cl == "Date") {
    "time"
  } else {
    "value"
  }
}

.get_data <- function(e, serie){
  e$x$data %>% 
    dplyr::select_(serie) %>% 
    unname() %>% 
    .[[1]]
}

.set_y_axis <- function(e, serie, y.index){
  
  if(length(e$x$opts$yAxis) - 1 < y.index){
    type <- .get_type(e, serie)
    
    axis <- list(type = type)
    
    if(type != "value"){
      axis$data <- .get_data(e, serie)
    }
    
    e$x$opts$yAxis[[y.index + 1]] <- axis
  }
  e
}

.set_axis_3D <- function(e, axis, serie, index){
  
  ax <- .r2axis3D(axis)
  
  if(length(e$x$opts[[ax]]) - 1 < index){
    type <- .get_type(e, serie)
    
    axis <- list(type = type)
    
    if(type != "value")
      axis$data <- unique(.get_data(e, serie))
    
    e$x$opts[[ax]][[index + 1]] <- axis
  }
  e
}

.set_x_axis <- function(e, x.index){
  
  serie <- e$x$mapping$x
  
  if(length(e$x$opts$xAxis) - 1 < x.index){
    type <- .get_type(e, serie)
    
    axis <- list(type = type, show = TRUE, boundaryGap = FALSE)
    
    if(type != "value"){
      axis$data <- .get_data(e, serie)
    }
    
    e$x$opts$xAxis[[x.index + 1]] <- axis
  }
  e
}

.set_z_axis <- function(e, serie, y.index){
  
  if(length(e$x$opts$yAxis) - 1 < y.index){
    type <- .get_type(e, serie)
    
    axis <- list(type = type)
    
    if(type != "value"){
      axis$data <- .get_data(e, serie)
    }
    
    e$x$opts$zAxis[[y.index + 1]] <- axis
  }
  e
}

.r2axis <- function(axis){
  paste0(axis, "Axis")
}

.r2axis3D <- function(axis){
  paste0(axis, "Axis3D")
}

.map_lines <- function(e, source.lon, source.lat, target.lon, target.lat){
  
  e$x$data %>% 
    dplyr::select_(
      source.lon, source.lat, target.lon, target.lat
    ) %>% 
    apply(., 1, function(x){
      x <- unname(x)
      list(
        c(x[1], x[2]),
        c(x[3], x[4])
      )
    }) 
}

.get_file <- function(file, convert){
  file <- system.file(file, package = "echarts4r")
  if(isTRUE(convert))
    e_convert_texture(file) -> file
  file
}

.build_cartesian3D <- function(e, ...){
  e$x$data %>%
    dplyr::select_(
      ...
    ) %>%
    unname() -> df
  
  apply(df, 1, function(x){
    list(value = x)
  })
}


.build_height <- function(e, serie, color){
  
  #data <- .build_data(e, e$x$mapping$x, serie, names = c("name", "height"))
  e$x$data %>%
    dplyr::select_(
      name = e$x$mapping$x,
      height = serie
    ) -> data
  
  names(data) <- c("name", "height")
  
  apply(data, 1, as.list) -> l
  
  if(!missing(color)){
    color <- e$x$data[[color]]
    
    for(i in 1:length(l)){
      is <- list(
        color = color[i]
      )
      l[[i]]$itemStyle <- is
    }
  }
  l
}

.correct_countries <- function(x){
  x <- gsub("^United States of America$", "United States", x)
  x <- gsub("^Viet Nam$", "Vietnam", x)
  x <- gsub("^United Kingdom of Great Britain and Northern Ireland$", "United Kingdom", x)
  x <- gsub("^Republic of Korea$", "Korea", x)
  x <- gsub("^Russian Federation$", "Russia", x)
  x
}