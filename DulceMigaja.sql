-- MySQL dump 10.13  Distrib 8.0.42, for Win64 (x86_64)
--
-- Host: localhost    Database: dulce_migaja
-- ------------------------------------------------------
-- Server version	8.1.0

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `ajustes_inventario`
--

DROP TABLE IF EXISTS `ajustes_inventario`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ajustes_inventario` (
  `id_ajuste` int NOT NULL AUTO_INCREMENT,
  `tipo_inventario` enum('materia_prima','producto_terminado') NOT NULL,
  `id_referencia` int NOT NULL,
  `cantidad_anterior` decimal(12,4) NOT NULL,
  `cantidad_nueva` decimal(12,4) NOT NULL,
  `motivo` text NOT NULL,
  `autorizado_por` int NOT NULL,
  `creado_en` datetime NOT NULL,
  PRIMARY KEY (`id_ajuste`),
  KEY `autorizado_por` (`autorizado_por`),
  CONSTRAINT `ajustes_inventario_ibfk_1` FOREIGN KEY (`autorizado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ajustes_inventario`
--

LOCK TABLES `ajustes_inventario` WRITE;
/*!40000 ALTER TABLE `ajustes_inventario` DISABLE KEYS */;
/*!40000 ALTER TABLE `ajustes_inventario` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `alembic_version`
--

DROP TABLE IF EXISTS `alembic_version`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `alembic_version` (
  `version_num` varchar(32) NOT NULL,
  PRIMARY KEY (`version_num`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alembic_version`
--

LOCK TABLES `alembic_version` WRITE;
/*!40000 ALTER TABLE `alembic_version` DISABLE KEYS */;
INSERT INTO `alembic_version` VALUES ('9c390faeb787');
/*!40000 ALTER TABLE `alembic_version` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `compras`
--

DROP TABLE IF EXISTS `compras`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `compras` (
  `id_compra` int NOT NULL AUTO_INCREMENT,
  `folio` varchar(20) NOT NULL,
  `id_proveedor` int NOT NULL,
  `fecha_compra` date NOT NULL,
  `total` decimal(12,2) NOT NULL,
  `observaciones` text,
  `creado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_compra`),
  UNIQUE KEY `folio` (`folio`),
  KEY `id_proveedor` (`id_proveedor`),
  KEY `creado_por` (`creado_por`),
  CONSTRAINT `compras_ibfk_2` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedores` (`id_proveedor`),
  CONSTRAINT `compras_ibfk_3` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `compras`
--

LOCK TABLES `compras` WRITE;
/*!40000 ALTER TABLE `compras` DISABLE KEYS */;
/*!40000 ALTER TABLE `compras` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cortes_diarios`
--

DROP TABLE IF EXISTS `cortes_diarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cortes_diarios` (
  `id_corte` int NOT NULL AUTO_INCREMENT,
  `fecha_corte` date NOT NULL,
  `total_ventas` decimal(12,2) NOT NULL,
  `total_tickets` int NOT NULL,
  `total_piezas` decimal(12,2) NOT NULL,
  `efectivo` decimal(12,2) NOT NULL,
  `tarjeta` decimal(12,2) NOT NULL,
  `transferencia` decimal(12,2) NOT NULL,
  `cancelaciones` int NOT NULL,
  `estado` enum('abierto','cerrado') NOT NULL,
  `cerrado_por` int DEFAULT NULL,
  `cerrado_en` datetime DEFAULT NULL,
  `creado_en` datetime NOT NULL,
  PRIMARY KEY (`id_corte`),
  UNIQUE KEY `fecha_corte` (`fecha_corte`),
  KEY `cerrado_por` (`cerrado_por`),
  CONSTRAINT `cortes_diarios_ibfk_1` FOREIGN KEY (`cerrado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cortes_diarios`
--

LOCK TABLES `cortes_diarios` WRITE;
/*!40000 ALTER TABLE `cortes_diarios` DISABLE KEYS */;
/*!40000 ALTER TABLE `cortes_diarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_compras`
--

DROP TABLE IF EXISTS `detalle_compras`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalle_compras` (
  `id_detalle_compra` int NOT NULL AUTO_INCREMENT,
  `id_compra` int NOT NULL,
  `id_materia` int NOT NULL,
  `cantidad_comprada` decimal(12,4) NOT NULL,
  `unidad_compra` varchar(20) NOT NULL,
  `factor_conversion` decimal(12,4) NOT NULL,
  `cantidad_base` decimal(12,4) NOT NULL,
  `costo_unitario` decimal(12,4) NOT NULL,
  `id_unidad_presentacion` int DEFAULT NULL,
  PRIMARY KEY (`id_detalle_compra`),
  KEY `id_compra` (`id_compra`),
  KEY `id_materia` (`id_materia`),
  KEY `id_unidad_presentacion` (`id_unidad_presentacion`),
  CONSTRAINT `detalle_compras_ibfk_1` FOREIGN KEY (`id_compra`) REFERENCES `compras` (`id_compra`) ON DELETE CASCADE,
  CONSTRAINT `detalle_compras_ibfk_2` FOREIGN KEY (`id_materia`) REFERENCES `materias_primas` (`id_materia`),
  CONSTRAINT `detalle_compras_ibfk_3` FOREIGN KEY (`id_unidad_presentacion`) REFERENCES `unidades_presentacion` (`id_unidad`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_compras`
--

LOCK TABLES `detalle_compras` WRITE;
/*!40000 ALTER TABLE `detalle_compras` DISABLE KEYS */;
/*!40000 ALTER TABLE `detalle_compras` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_produccion`
--

DROP TABLE IF EXISTS `detalle_produccion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalle_produccion` (
  `id_det_prod` int NOT NULL AUTO_INCREMENT,
  `id_produccion` int NOT NULL,
  `id_materia` int NOT NULL,
  `cantidad_requerida` decimal(12,4) NOT NULL,
  `cantidad_descontada` decimal(12,4) NOT NULL,
  PRIMARY KEY (`id_det_prod`),
  KEY `id_materia` (`id_materia`),
  KEY `id_produccion` (`id_produccion`),
  CONSTRAINT `detalle_produccion_ibfk_1` FOREIGN KEY (`id_materia`) REFERENCES `materias_primas` (`id_materia`),
  CONSTRAINT `detalle_produccion_ibfk_2` FOREIGN KEY (`id_produccion`) REFERENCES `produccion` (`id_produccion`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_produccion`
--

LOCK TABLES `detalle_produccion` WRITE;
/*!40000 ALTER TABLE `detalle_produccion` DISABLE KEYS */;
/*!40000 ALTER TABLE `detalle_produccion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_recetas`
--

DROP TABLE IF EXISTS `detalle_recetas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalle_recetas` (
  `id_detalle_receta` int NOT NULL AUTO_INCREMENT,
  `id_receta` int NOT NULL,
  `id_materia` int NOT NULL,
  `cantidad_requerida` decimal(12,4) NOT NULL,
  `orden` smallint NOT NULL,
  `id_unidad_presentacion` int DEFAULT NULL,
  `cantidad_presentacion` decimal(12,4) DEFAULT NULL,
  PRIMARY KEY (`id_detalle_receta`),
  UNIQUE KEY `uq_det_receta_materia` (`id_receta`,`id_materia`),
  KEY `id_materia` (`id_materia`),
  KEY `id_unidad_presentacion` (`id_unidad_presentacion`),
  CONSTRAINT `detalle_recetas_ibfk_1` FOREIGN KEY (`id_materia`) REFERENCES `materias_primas` (`id_materia`),
  CONSTRAINT `detalle_recetas_ibfk_2` FOREIGN KEY (`id_receta`) REFERENCES `recetas` (`id_receta`) ON DELETE CASCADE,
  CONSTRAINT `detalle_recetas_ibfk_3` FOREIGN KEY (`id_unidad_presentacion`) REFERENCES `unidades_presentacion` (`id_unidad`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=136 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_recetas`
--

LOCK TABLES `detalle_recetas` WRITE;
/*!40000 ALTER TABLE `detalle_recetas` DISABLE KEYS */;
INSERT INTO `detalle_recetas` VALUES (1,1,1,500.0000,1,NULL,NULL),(2,1,2,120.0000,2,NULL,NULL),(3,1,3,80.0000,3,NULL,NULL),(4,1,4,150.0000,4,NULL,NULL),(5,1,6,100.0000,5,NULL,NULL),(6,1,5,8.0000,6,NULL,NULL),(7,1,7,5.0000,7,NULL,NULL),(8,1,8,5.0000,8,NULL,NULL),(9,1,13,240.0000,9,NULL,NULL),(19,3,1,550.0000,1,NULL,NULL),(20,3,2,80.0000,2,NULL,NULL),(21,3,3,200.0000,3,NULL,NULL),(22,3,4,120.0000,4,NULL,NULL),(23,3,6,100.0000,5,NULL,NULL),(24,3,5,8.0000,6,NULL,NULL),(25,3,7,6.0000,7,NULL,NULL),(26,3,12,210.0000,8,NULL,NULL),(27,3,11,210.0000,9,NULL,NULL),(28,4,1,450.0000,1,NULL,NULL),(29,4,2,100.0000,2,NULL,NULL),(30,4,3,60.0000,3,NULL,NULL),(31,4,4,160.0000,4,NULL,NULL),(32,4,6,100.0000,5,NULL,NULL),(33,4,5,8.0000,6,NULL,NULL),(34,4,7,5.0000,7,NULL,NULL),(35,4,9,30.0000,8,NULL,NULL),(36,4,15,250.0000,9,NULL,NULL),(37,5,1,550.0000,1,NULL,NULL),(38,5,2,70.0000,2,NULL,NULL),(39,5,3,200.0000,3,NULL,NULL),(40,5,4,120.0000,4,NULL,NULL),(41,5,6,100.0000,5,NULL,NULL),(42,5,5,8.0000,6,NULL,NULL),(43,5,7,6.0000,7,NULL,NULL),(44,5,16,280.0000,8,NULL,NULL),(45,6,1,400.0000,1,NULL,NULL),(46,6,2,80.0000,2,NULL,NULL),(47,6,3,180.0000,3,NULL,NULL),(48,6,6,60.0000,4,NULL,NULL),(49,6,7,3.0000,5,NULL,NULL),(50,6,8,4.0000,6,NULL,NULL),(51,6,20,50.0000,7,NULL,NULL),(52,6,17,200.0000,8,NULL,NULL),(53,7,1,500.0000,1,NULL,NULL),(54,7,2,60.0000,2,NULL,NULL),(55,7,3,80.0000,3,NULL,NULL),(56,7,4,180.0000,4,NULL,NULL),(57,7,6,80.0000,5,NULL,NULL),(58,7,5,10.0000,6,NULL,NULL),(59,7,7,6.0000,7,NULL,NULL),(60,7,10,15.0000,8,NULL,NULL),(61,7,18,200.0000,9,NULL,NULL),(62,8,1,300.0000,1,NULL,NULL),(63,8,9,80.0000,2,NULL,NULL),(64,8,2,120.0000,3,NULL,NULL),(65,8,3,150.0000,4,NULL,NULL),(66,8,6,200.0000,5,NULL,NULL),(67,8,7,3.0000,6,NULL,NULL),(68,8,13,150.0000,7,NULL,NULL),(69,9,1,500.0000,1,NULL,NULL),(70,9,2,80.0000,2,NULL,NULL),(71,9,3,60.0000,3,NULL,NULL),(72,9,4,160.0000,4,NULL,NULL),(73,9,6,100.0000,5,NULL,NULL),(74,9,5,8.0000,6,NULL,NULL),(75,9,7,5.0000,7,NULL,NULL),(76,9,8,6.0000,8,NULL,NULL),(77,9,19,240.0000,9,NULL,NULL),(78,10,1,480.0000,1,NULL,NULL),(79,10,2,100.0000,2,NULL,NULL),(80,10,3,60.0000,3,NULL,NULL),(81,10,4,160.0000,4,NULL,NULL),(82,10,6,100.0000,5,NULL,NULL),(83,10,5,10.0000,6,NULL,NULL),(84,10,7,5.0000,7,NULL,NULL),(85,10,8,4.0000,8,NULL,NULL),(86,10,20,60.0000,9,NULL,NULL),(87,10,14,240.0000,10,NULL,NULL),(88,11,1,520.0000,1,NULL,NULL),(89,11,2,80.0000,2,NULL,NULL),(90,11,3,200.0000,3,NULL,NULL),(91,11,4,120.0000,4,NULL,NULL),(92,11,6,100.0000,5,NULL,NULL),(93,11,5,8.0000,6,NULL,NULL),(94,11,7,6.0000,7,NULL,NULL),(95,11,8,4.0000,8,NULL,NULL),(96,11,13,150.0000,9,NULL,NULL),(97,11,14,120.0000,10,NULL,NULL),(98,12,1,600.0000,1,NULL,NULL),(99,12,2,80.0000,2,NULL,NULL),(100,12,3,250.0000,3,NULL,NULL),(101,12,4,100.0000,4,NULL,NULL),(102,12,6,150.0000,5,NULL,NULL),(103,12,5,10.0000,6,NULL,NULL),(104,12,7,6.0000,7,NULL,NULL),(105,12,8,5.0000,8,NULL,NULL),(106,12,20,80.0000,9,NULL,NULL),(107,13,20,120.0000,1,NULL,NULL),(108,13,17,122.0000,2,NULL,NULL),(118,2,1,480.0000,1,NULL,NULL),(119,2,2,120.0000,2,NULL,NULL),(120,2,3,90.0000,3,NULL,NULL),(121,2,4,150.0000,4,NULL,NULL),(122,2,5,8.0000,5,NULL,NULL),(123,2,6,100.0000,6,NULL,NULL),(124,2,7,5.0000,7,NULL,NULL),(125,2,9,50.0000,8,NULL,NULL),(126,2,13,200.0000,9,NULL,NULL),(127,14,20,12.0000,1,NULL,NULL),(128,14,13,12.0000,2,NULL,NULL),(134,16,4,3000.0000,1,14,3.0000),(135,16,20,20.0000,2,76,2.0000);
/*!40000 ALTER TABLE `detalle_recetas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_ventas`
--

DROP TABLE IF EXISTS `detalle_ventas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalle_ventas` (
  `id_detalle_venta` int NOT NULL AUTO_INCREMENT,
  `id_venta` int NOT NULL,
  `id_producto` int NOT NULL,
  `cantidad` decimal(10,2) NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  `descuento_pct` decimal(5,2) NOT NULL,
  `subtotal` decimal(12,2) NOT NULL,
  PRIMARY KEY (`id_detalle_venta`),
  KEY `id_venta` (`id_venta`),
  KEY `fk_detventa_producto` (`id_producto`),
  CONSTRAINT `detalle_ventas_ibfk_2` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE CASCADE,
  CONSTRAINT `fk_detventa_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_ventas`
--

LOCK TABLES `detalle_ventas` WRITE;
/*!40000 ALTER TABLE `detalle_ventas` DISABLE KEYS */;
/*!40000 ALTER TABLE `detalle_ventas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventario_pt`
--

DROP TABLE IF EXISTS `inventario_pt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventario_pt` (
  `id_inventario` int NOT NULL AUTO_INCREMENT,
  `id_producto` int NOT NULL,
  `stock_actual` decimal(12,2) NOT NULL DEFAULT '0.00',
  `stock_minimo` decimal(12,2) NOT NULL DEFAULT '0.00',
  `ultima_actualizacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_inventario`),
  UNIQUE KEY `uq_inv_producto` (`id_producto`),
  CONSTRAINT `fk_inv_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Stock en tiempo real de cada producto terminado.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventario_pt`
--

LOCK TABLES `inventario_pt` WRITE;
/*!40000 ALTER TABLE `inventario_pt` DISABLE KEYS */;
INSERT INTO `inventario_pt` VALUES (1,1,0.00,20.00,'2026-03-24 14:42:13'),(2,2,0.00,20.00,'2026-03-24 14:42:13'),(3,3,0.00,20.00,'2026-03-24 14:42:13'),(4,4,0.00,15.00,'2026-03-24 14:42:13'),(5,5,0.00,20.00,'2026-03-24 14:42:13'),(6,6,0.00,15.00,'2026-03-24 14:42:13'),(7,7,0.00,15.00,'2026-03-24 14:42:13'),(8,8,0.00,15.00,'2026-03-24 14:42:13'),(9,9,0.00,20.00,'2026-03-24 14:42:13'),(10,10,0.00,20.00,'2026-03-24 14:42:13'),(11,11,0.00,15.00,'2026-03-24 14:42:13'),(12,12,0.00,25.00,'2026-03-24 14:42:13');
/*!40000 ALTER TABLE `inventario_pt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `logs_sistema`
--

DROP TABLE IF EXISTS `logs_sistema`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `logs_sistema` (
  `id_log` bigint NOT NULL AUTO_INCREMENT,
  `tipo` enum('error','acceso','cambio_usuario','venta','compra','produccion','ajuste_inv','solicitud','salida_efectivo','seguridad') NOT NULL,
  `nivel` enum('INFO','WARNING','ERROR','CRITICAL') NOT NULL,
  `id_usuario` int DEFAULT NULL,
  `modulo` varchar(60) DEFAULT NULL,
  `accion` varchar(120) DEFAULT NULL,
  `descripcion` text,
  `ip_origen` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `referencia_id` int DEFAULT NULL,
  `referencia_tipo` varchar(60) DEFAULT NULL,
  `creado_en` datetime NOT NULL,
  PRIMARY KEY (`id_log`),
  KEY `id_usuario` (`id_usuario`),
  CONSTRAINT `logs_sistema_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `logs_sistema`
--

LOCK TABLES `logs_sistema` WRITE;
/*!40000 ALTER TABLE `logs_sistema` DISABLE KEYS */;
/*!40000 ALTER TABLE `logs_sistema` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `materias_primas`
--

DROP TABLE IF EXISTS `materias_primas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `materias_primas` (
  `id_materia` int NOT NULL AUTO_INCREMENT,
  `uuid_materia` varchar(36) NOT NULL,
  `nombre` varchar(120) NOT NULL,
  `categoria` varchar(60) DEFAULT NULL,
  `unidad_base` varchar(20) NOT NULL,
  `stock_actual` decimal(12,4) NOT NULL,
  `stock_minimo` decimal(12,4) NOT NULL,
  `estatus` enum('activo','inactivo') NOT NULL,
  `creado_en` datetime NOT NULL,
  `actualizado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_materia`),
  UNIQUE KEY `uuid_materia` (`uuid_materia`),
  KEY `creado_por` (`creado_por`),
  CONSTRAINT `materias_primas_ibfk_1` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `materias_primas`
--

LOCK TABLES `materias_primas` WRITE;
/*!40000 ALTER TABLE `materias_primas` DISABLE KEYS */;
INSERT INTO `materias_primas` VALUES (1,'84bb422b-2613-11f1-9474-c01850d072b8','Harina de Trigo','Harinas','g',40000.0000,5000.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(2,'84bd05a6-2613-11f1-9474-c01850d072b8','Azúcar Refinada','Endulzantes','g',8000.0000,2000.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(3,'84bd0bd2-2613-11f1-9474-c01850d072b8','Mantequilla','Grasas','g',6000.0000,2000.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(4,'84bd0f0a-2613-11f1-9474-c01850d072b8','Leche Entera','Lácteos','ml',5000.0000,1000.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(5,'84bd1c40-2613-11f1-9474-c01850d072b8','Levadura Seca','Fermentación','g',500.0000,100.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(6,'84bd1fe6-2613-11f1-9474-c01850d072b8','Huevo','Proteínas','g',3000.0000,600.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(7,'84bd2126-2613-11f1-9474-c01850d072b8','Sal','Condimentos','g',2000.0000,200.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(8,'84bd22ba-2613-11f1-9474-c01850d072b8','Esencia de Vainilla','Saborizantes','ml',300.0000,50.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(9,'84bd23ed-2613-11f1-9474-c01850d072b8','Cocoa en Polvo','Saborizantes','g',1500.0000,300.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(10,'84bd24f6-2613-11f1-9474-c01850d072b8','Canela Molida','Especias','g',500.0000,100.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(11,'84bd2613-2613-11f1-9474-c01850d072b8','Queso Crema','Lácteos','g',2000.0000,500.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(12,'84bd5a67-2613-11f1-9474-c01850d072b8','Cajeta','Rellenos','g',1500.0000,300.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(13,'84bd64c5-2613-11f1-9474-c01850d072b8','Crema Pastelera','Rellenos','g',3000.0000,500.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(14,'84bd6626-2613-11f1-9474-c01850d072b8','Mermelada de Fresa','Rellenos','g',2000.0000,400.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(15,'84bd6799-2613-11f1-9474-c01850d072b8','Crema de Avellana','Rellenos','g',1500.0000,300.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(16,'84bd694b-2613-11f1-9474-c01850d072b8','Dulce de Leche','Rellenos','g',1800.0000,300.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(17,'84bd6a5b-2613-11f1-9474-c01850d072b8','Crema de Limón','Rellenos','g',1000.0000,200.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(18,'84bd6b7d-2613-11f1-9474-c01850d072b8','Piloncillo','Endulzantes','g',2000.0000,400.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(19,'84bd6c9b-2613-11f1-9474-c01850d072b8','Requesón','Lácteos','g',1200.0000,300.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(20,'84bd6dbd-2613-11f1-9474-c01850d072b8','Azúcar Glass','Endulzantes','g',2000.0000,300.0000,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1);
/*!40000 ALTER TABLE `materias_primas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mermas`
--

DROP TABLE IF EXISTS `mermas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mermas` (
  `id_merma` int NOT NULL AUTO_INCREMENT,
  `tipo_objeto` enum('materia_prima','producto_terminado','lote_produccion') NOT NULL,
  `id_referencia` int NOT NULL,
  `cantidad` decimal(12,4) NOT NULL,
  `unidad` varchar(20) NOT NULL,
  `causa` enum('caducidad','quemado_horneado','caida_accidente','error_produccion','rotura_empaque','contaminacion','otro') NOT NULL,
  `descripcion` text,
  `id_produccion` int DEFAULT NULL,
  `registrado_por` int NOT NULL,
  `fecha_merma` datetime NOT NULL,
  `creado_en` datetime NOT NULL,
  PRIMARY KEY (`id_merma`),
  KEY `id_produccion` (`id_produccion`),
  KEY `registrado_por` (`registrado_por`),
  CONSTRAINT `mermas_ibfk_1` FOREIGN KEY (`id_produccion`) REFERENCES `produccion` (`id_produccion`) ON DELETE SET NULL,
  CONSTRAINT `mermas_ibfk_2` FOREIGN KEY (`registrado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mermas`
--

LOCK TABLES `mermas` WRITE;
/*!40000 ALTER TABLE `mermas` DISABLE KEYS */;
/*!40000 ALTER TABLE `mermas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `produccion`
--

DROP TABLE IF EXISTS `produccion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `produccion` (
  `id_produccion` int NOT NULL AUTO_INCREMENT,
  `folio_lote` varchar(20) NOT NULL,
  `id_producto` int NOT NULL,
  `id_receta` int NOT NULL,
  `cantidad_lotes` decimal(10,2) NOT NULL,
  `piezas_esperadas` decimal(10,2) NOT NULL,
  `piezas_producidas` decimal(10,2) DEFAULT NULL,
  `estado` enum('pendiente','en_proceso','finalizado','cancelado') NOT NULL,
  `fecha_inicio` datetime DEFAULT NULL,
  `fecha_fin_estimado` datetime DEFAULT NULL,
  `fecha_fin_real` datetime DEFAULT NULL,
  `operario_id` int DEFAULT NULL,
  `observaciones` text,
  `creado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_produccion`),
  UNIQUE KEY `folio_lote` (`folio_lote`),
  KEY `creado_por` (`creado_por`),
  KEY `id_receta` (`id_receta`),
  KEY `operario_id` (`operario_id`),
  KEY `fk_produccion_producto` (`id_producto`),
  CONSTRAINT `fk_produccion_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`),
  CONSTRAINT `produccion_ibfk_1` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `produccion_ibfk_3` FOREIGN KEY (`id_receta`) REFERENCES `recetas` (`id_receta`),
  CONSTRAINT `produccion_ibfk_4` FOREIGN KEY (`operario_id`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `produccion`
--

LOCK TABLES `produccion` WRITE;
/*!40000 ALTER TABLE `produccion` DISABLE KEYS */;
/*!40000 ALTER TABLE `produccion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos`
--

DROP TABLE IF EXISTS `productos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos` (
  `id_producto` int NOT NULL AUTO_INCREMENT,
  `uuid_producto` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text COLLATE utf8mb4_unicode_ci,
  `precio_venta` decimal(10,2) NOT NULL DEFAULT '0.00',
  `estatus` enum('activo','inactivo') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'activo',
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_producto`),
  UNIQUE KEY `uq_uuid_producto` (`uuid_producto`),
  KEY `fk_prod_creado_por` (`creado_por`),
  CONSTRAINT `fk_prod_creado_por` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de productos terminados (datos estáticos).';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos`
--

LOCK TABLES `productos` WRITE;
/*!40000 ALTER TABLE `productos` DISABLE KEYS */;
INSERT INTO `productos` VALUES (1,'84e8ac4f-2613-11f1-9474-c01850d072b8','Concha de Crema Pastelera','Concha suave rellena de crema pastelera clásica',24.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(2,'84e8d2df-2613-11f1-9474-c01850d072b8','Concha de Chocolate','Concha de cocoa rellena de crema de chocolate',26.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(3,'84e8d5db-2613-11f1-9474-c01850d072b8','Cuernito de Cajeta y Queso','Cuernito hojaldrado relleno de cajeta y queso crema',26.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(4,'84e8d72f-2613-11f1-9474-c01850d072b8','Dona de Crema de Avellana','Dona con glaseado de chocolate rellena de crema de avellana',28.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(5,'84e8d842-2613-11f1-9474-c01850d072b8','Cuernito de Dulce de Leche','Cuernito hojaldrado relleno de dulce de leche',25.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(6,'84e8d976-2613-11f1-9474-c01850d072b8','Polvorón de Crema de Limón','Polvorón de mantequilla relleno de crema de limón',26.00,'activo','2026-03-22 11:21:10','2026-03-24 16:26:10',NULL),(7,'84e8da8e-2613-11f1-9474-c01850d072b8','Trenza de Canela y Piloncillo','Trenza de masa dulce rellena de piloncillo y canela',24.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(8,'84e8dbb3-2613-11f1-9474-c01850d072b8','Volcán de Chocolate','Pan individual de cocoa con centro de crema de chocolate',30.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(9,'84e8dd04-2613-11f1-9474-c01850d072b8','Mogote de Requesón y Vainilla','Pan redondo esponjoso relleno de requesón con vainilla',24.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(10,'84e8de28-2613-11f1-9474-c01850d072b8','Dona de Mermelada de Fresa','Dona con azúcar glass rellena de mermelada de fresa',22.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(11,'84e8df44-2613-11f1-9474-c01850d072b8','Cuernito de Crema Pastelera y Fresa','Cuernito hojaldrado con doble relleno de crema pastelera y fresa',28.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL),(12,'84e8e05d-2613-11f1-9474-c01850d072b8','Brioche de Mantequilla y Azúcar Glass','Pan brioche relleno de mantequilla y cubierto de azúcar glass',20.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10',NULL);
/*!40000 ALTER TABLE `productos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos_terminados`
--

DROP TABLE IF EXISTS `productos_terminados`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos_terminados` (
  `id_producto` int NOT NULL AUTO_INCREMENT,
  `uuid_producto` varchar(36) NOT NULL,
  `nombre` varchar(120) NOT NULL,
  `descripcion` text,
  `precio_venta` decimal(10,2) NOT NULL,
  `stock_actual` decimal(12,2) NOT NULL,
  `stock_minimo` decimal(12,2) NOT NULL,
  `estatus` enum('activo','inactivo') NOT NULL,
  `creado_en` datetime NOT NULL,
  `actualizado_en` datetime NOT NULL,
  PRIMARY KEY (`id_producto`),
  UNIQUE KEY `uuid_producto` (`uuid_producto`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos_terminados`
--

LOCK TABLES `productos_terminados` WRITE;
/*!40000 ALTER TABLE `productos_terminados` DISABLE KEYS */;
INSERT INTO `productos_terminados` VALUES (1,'84e8ac4f-2613-11f1-9474-c01850d072b8','Concha de Crema Pastelera','Concha suave rellena de crema pastelera clásica',24.00,0.00,20.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(2,'84e8d2df-2613-11f1-9474-c01850d072b8','Concha de Chocolate','Concha de cocoa rellena de crema de chocolate',26.00,0.00,20.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(3,'84e8d5db-2613-11f1-9474-c01850d072b8','Cuernito de Cajeta y Queso','Cuernito hojaldrado relleno de cajeta y queso crema',26.00,0.00,20.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(4,'84e8d72f-2613-11f1-9474-c01850d072b8','Dona de Crema de Avellana','Dona con glaseado de chocolate rellena de crema de avellana',28.00,0.00,15.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(5,'84e8d842-2613-11f1-9474-c01850d072b8','Cuernito de Dulce de Leche','Cuernito hojaldrado relleno de dulce de leche',25.00,0.00,20.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(6,'84e8d976-2613-11f1-9474-c01850d072b8','Polvorón de Crema de Limón','Polvorón de mantequilla relleno de crema de limón',26.00,0.00,15.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(7,'84e8da8e-2613-11f1-9474-c01850d072b8','Trenza de Canela y Piloncillo','Trenza de masa dulce rellena de piloncillo y canela',24.00,0.00,15.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(8,'84e8dbb3-2613-11f1-9474-c01850d072b8','Volcán de Chocolate','Pan individual de cocoa con centro de crema de chocolate',30.00,0.00,15.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(9,'84e8dd04-2613-11f1-9474-c01850d072b8','Mogote de Requesón y Vainilla','Pan redondo esponjoso relleno de requesón con vainilla',24.00,0.00,20.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(10,'84e8de28-2613-11f1-9474-c01850d072b8','Dona de Mermelada de Fresa','Dona con azúcar glass rellena de mermelada de fresa',22.00,0.00,20.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(11,'84e8df44-2613-11f1-9474-c01850d072b8','Cuernito de Crema Pastelera y Fresa','Cuernito hojaldrado con doble relleno de crema pastelera y fresa',28.00,0.00,15.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10'),(12,'84e8e05d-2613-11f1-9474-c01850d072b8','Brioche de Mantequilla y Azúcar Glass','Pan brioche relleno de mantequilla y cubierto de azúcar glass',20.00,0.00,25.00,'activo','2026-03-22 11:21:10','2026-03-22 11:21:10');
/*!40000 ALTER TABLE `productos_terminados` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `proveedores`
--

DROP TABLE IF EXISTS `proveedores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `proveedores` (
  `id_proveedor` int NOT NULL AUTO_INCREMENT,
  `uuid_proveedor` varchar(36) NOT NULL,
  `nombre` varchar(150) NOT NULL,
  `rfc` varchar(13) DEFAULT NULL,
  `contacto` varchar(120) DEFAULT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `direccion` text,
  `estatus` enum('activo','inactivo') NOT NULL,
  `creado_en` datetime NOT NULL,
  `actualizado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_proveedor`),
  UNIQUE KEY `uuid_proveedor` (`uuid_proveedor`),
  UNIQUE KEY `rfc` (`rfc`),
  KEY `creado_por` (`creado_por`),
  CONSTRAINT `proveedores_ibfk_1` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proveedores`
--

LOCK TABLES `proveedores` WRITE;
/*!40000 ALTER TABLE `proveedores` DISABLE KEYS */;
/*!40000 ALTER TABLE `proveedores` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `recetas`
--

DROP TABLE IF EXISTS `recetas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recetas` (
  `id_receta` int NOT NULL AUTO_INCREMENT,
  `id_producto` int DEFAULT NULL COMMENT 'Producto terminado que produce esta receta',
  `uuid_receta` varchar(36) NOT NULL,
  `nombre` varchar(120) NOT NULL,
  `descripcion` text,
  `rendimiento` decimal(10,2) NOT NULL,
  `unidad_rendimiento` varchar(20) NOT NULL,
  `precio_venta` decimal(10,2) DEFAULT NULL,
  `estatus` enum('activo','inactivo') NOT NULL,
  `creado_en` datetime NOT NULL,
  `actualizado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_receta`),
  UNIQUE KEY `uuid_receta` (`uuid_receta`),
  KEY `creado_por` (`creado_por`),
  KEY `fk_receta_producto` (`id_producto`),
  CONSTRAINT `fk_receta_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL,
  CONSTRAINT `recetas_ibfk_1` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `recetas`
--

LOCK TABLES `recetas` WRITE;
/*!40000 ALTER TABLE `recetas` DISABLE KEYS */;
INSERT INTO `recetas` VALUES (1,1,'84bf5c5f-2613-11f1-9474-c01850d072b8','Concha de Crema Pastelera','Concha suave con cubierta de azúcar, rellena de crema pastelera clásica',12.00,'pza',24.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(2,2,'84c00cea-2613-11f1-9474-c01850d072b8','Concha de Chocolate','Concha con cubierta de cocoa, rellena de crema de chocolate',12.00,'pza',26.00,'activo','2026-03-22 11:21:09','2026-03-23 20:16:19',1),(3,3,'84c00fa7-2613-11f1-9474-c01850d072b8','Cuernito de Cajeta y Queso','Cuernito hojaldrado relleno de cajeta con queso crema',14.00,'pza',26.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(4,4,'84c010d4-2613-11f1-9474-c01850d072b8','Dona de Crema de Avellana','Dona esponjosa con glaseado de chocolate, rellena de crema de avellana',10.00,'pza',28.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(5,5,'84c011fa-2613-11f1-9474-c01850d072b8','Cuernito de Dulce de Leche','Cuernito hojaldrado relleno de dulce de leche cremoso',14.00,'pza',25.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(6,6,'84c01311-2613-11f1-9474-c01850d072b8','Polvorón de Crema de Limón','Polvorón suave con base de mantequilla, relleno de crema de limón fresca',10.00,'pza',26.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(7,7,'84c014a3-2613-11f1-9474-c01850d072b8','Trenza de Canela y Piloncillo','Trenza de masa dulce con canela, rellena de piloncillo derretido',10.00,'pza',24.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(8,8,'84c01646-2613-11f1-9474-c01850d072b8','Volcán de Chocolate','Pan individual de cocoa con centro de crema de chocolate',10.00,'pza',30.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(9,9,'84c0191d-2613-11f1-9474-c01850d072b8','Mogote de Requesón y Vainilla','Pan redondo y esponjoso relleno de requesón suavizado con vainilla',12.00,'pza',24.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(10,10,'84c01b2b-2613-11f1-9474-c01850d072b8','Dona de Mermelada de Fresa','Dona esponjosa con azúcar glass, rellena de mermelada de fresa',12.00,'pza',22.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(11,11,'84c01c58-2613-11f1-9474-c01850d072b8','Cuernito de Crema Pastelera y Fresa','Cuernito hojaldrado con doble relleno de crema pastelera y mermelada de fresa',12.00,'pza',28.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(12,12,'84c01e4e-2613-11f1-9474-c01850d072b8','Brioche de Mantequilla y Azúcar Glass','Pan tipo brioche esponjoso relleno de mantequilla y cubierto de azúcar glass',16.00,'pza',20.00,'activo','2026-03-22 11:21:09','2026-03-24 14:56:51',1),(13,NULL,'6f56eaeb-3261-4379-a793-b206f4d1943e','Salvador','bla bla bla',12.00,'pza',15.00,'activo','2026-03-23 20:13:06','2026-03-23 20:13:06',NULL),(14,8,'9e3edc23-d65c-4ff9-9064-0bbc92a423d5','Volcan de Chocolate - 12 piezas','bla bla',12.00,'pza',12.00,'activo','2026-03-24 09:38:32','2026-03-24 09:38:32',NULL),(16,12,'c2c50642-c1f6-4a90-80aa-b2bc93fc822a','Brionche para 2','bla bla',2.00,'pza',50.00,'activo','2026-03-24 15:11:43','2026-03-24 15:12:24',NULL);
/*!40000 ALTER TABLE `recetas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id_rol` smallint NOT NULL AUTO_INCREMENT,
  `clave_rol` varchar(10) NOT NULL,
  `nombre_rol` varchar(50) NOT NULL,
  `descripcion` text,
  PRIMARY KEY (`id_rol`),
  UNIQUE KEY `clave_rol` (`clave_rol`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'admin','Administrador','Acceso total al sistema'),(2,'empleado','Empleado','Acceso general de empleado'),(3,'panadero','Panadero','Acceso a módulos de producción');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `salidas_efectivo`
--

DROP TABLE IF EXISTS `salidas_efectivo`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `salidas_efectivo` (
  `id_salida` int NOT NULL AUTO_INCREMENT,
  `folio_salida` varchar(20) NOT NULL,
  `id_proveedor` int DEFAULT NULL,
  `categoria` enum('compra_insumos','servicios_utilities','mantenimiento','otros') NOT NULL,
  `descripcion` varchar(255) NOT NULL,
  `monto` decimal(12,2) NOT NULL,
  `fecha_salida` date NOT NULL,
  `estado` enum('pendiente','aprobada','rechazada') NOT NULL,
  `id_corte` int DEFAULT NULL,
  `registrado_por` int NOT NULL,
  `aprobado_por` int DEFAULT NULL,
  `creado_en` datetime NOT NULL,
  `actualizado_en` datetime NOT NULL,
  PRIMARY KEY (`id_salida`),
  UNIQUE KEY `folio_salida` (`folio_salida`),
  KEY `aprobado_por` (`aprobado_por`),
  KEY `id_corte` (`id_corte`),
  KEY `id_proveedor` (`id_proveedor`),
  KEY `registrado_por` (`registrado_por`),
  CONSTRAINT `salidas_efectivo_ibfk_1` FOREIGN KEY (`aprobado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `salidas_efectivo_ibfk_2` FOREIGN KEY (`id_corte`) REFERENCES `cortes_diarios` (`id_corte`) ON DELETE SET NULL,
  CONSTRAINT `salidas_efectivo_ibfk_3` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedores` (`id_proveedor`) ON DELETE SET NULL,
  CONSTRAINT `salidas_efectivo_ibfk_4` FOREIGN KEY (`registrado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `salidas_efectivo`
--

LOCK TABLES `salidas_efectivo` WRITE;
/*!40000 ALTER TABLE `salidas_efectivo` DISABLE KEYS */;
/*!40000 ALTER TABLE `salidas_efectivo` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sesiones`
--

DROP TABLE IF EXISTS `sesiones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sesiones` (
  `id_sesion` varchar(64) NOT NULL,
  `id_usuario` int NOT NULL,
  `ip_inicio` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `csrf_token` varchar(64) NOT NULL,
  `activa` tinyint(1) NOT NULL,
  `expira_en` datetime NOT NULL,
  `creado_en` datetime NOT NULL,
  `ultimo_acceso` datetime NOT NULL,
  PRIMARY KEY (`id_sesion`),
  KEY `id_usuario` (`id_usuario`),
  CONSTRAINT `sesiones_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sesiones`
--

LOCK TABLES `sesiones` WRITE;
/*!40000 ALTER TABLE `sesiones` DISABLE KEYS */;
/*!40000 ALTER TABLE `sesiones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tickets`
--

DROP TABLE IF EXISTS `tickets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tickets` (
  `id_ticket` int NOT NULL AUTO_INCREMENT,
  `id_venta` int NOT NULL,
  `contenido_json` json NOT NULL,
  `impreso` tinyint(1) NOT NULL,
  `generado_en` datetime NOT NULL,
  PRIMARY KEY (`id_ticket`),
  UNIQUE KEY `id_venta` (`id_venta`),
  CONSTRAINT `tickets_ibfk_1` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tickets`
--

LOCK TABLES `tickets` WRITE;
/*!40000 ALTER TABLE `tickets` DISABLE KEYS */;
/*!40000 ALTER TABLE `tickets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `unidades_presentacion`
--

DROP TABLE IF EXISTS `unidades_presentacion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `unidades_presentacion` (
  `id_unidad` int NOT NULL AUTO_INCREMENT,
  `id_materia` int NOT NULL,
  `nombre` varchar(80) NOT NULL,
  `simbolo` varchar(20) NOT NULL,
  `factor_a_base` decimal(14,2) NOT NULL,
  `uso` enum('compra','receta','ambos') NOT NULL,
  `activo` tinyint(1) NOT NULL DEFAULT '1',
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_unidad`),
  UNIQUE KEY `uq_unidad_materia_simbolo` (`id_materia`,`simbolo`),
  CONSTRAINT `unidades_presentacion_ibfk_1` FOREIGN KEY (`id_materia`) REFERENCES `materias_primas` (`id_materia`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=78 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `unidades_presentacion`
--

LOCK TABLES `unidades_presentacion` WRITE;
/*!40000 ALTER TABLE `unidades_presentacion` DISABLE KEYS */;
INSERT INTO `unidades_presentacion` VALUES (1,1,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(2,1,'Saco 25 kg','saco',25000.00,'compra',1,'2026-03-24 15:03:49'),(3,1,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(4,1,'Taza cernida','taza',120.00,'receta',1,'2026-03-24 15:03:49'),(5,2,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(6,2,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(7,2,'Cucharada','cda',12.00,'receta',1,'2026-03-24 15:03:49'),(8,2,'Taza','taza',200.00,'receta',1,'2026-03-24 15:03:49'),(9,3,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(10,3,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(11,3,'Barra 90 g','barra',90.00,'receta',1,'2026-03-24 15:03:49'),(12,3,'Cucharada','cda',14.00,'receta',1,'2026-03-24 15:03:49'),(13,4,'Galón (3.785 L)','gal',3785.00,'compra',1,'2026-03-24 15:03:49'),(14,4,'Litro','lt',1000.00,'ambos',1,'2026-03-24 15:03:49'),(15,4,'Taza (240 ml)','taza',240.00,'receta',1,'2026-03-24 15:03:49'),(16,4,'Mililitro','ml',1.00,'receta',1,'2026-03-24 15:03:49'),(17,5,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(18,5,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(19,5,'Cucharadita','cdta',3.00,'receta',1,'2026-03-24 15:03:49'),(20,6,'Kilo (~16-17 pzas)','kg',16.67,'compra',1,'2026-03-24 15:03:49'),(21,6,'Docena','doc',12.00,'compra',1,'2026-03-24 15:03:49'),(22,6,'Caja 30 pzas','caja',30.00,'compra',1,'2026-03-24 15:03:49'),(23,6,'Pieza','pza',1.00,'receta',1,'2026-03-24 15:03:49'),(24,7,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(25,7,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(26,7,'Cucharadita','cdta',5.00,'receta',1,'2026-03-24 15:03:49'),(27,7,'Pizca','pizca',0.50,'receta',1,'2026-03-24 15:03:49'),(28,8,'Litro','lt',1000.00,'compra',1,'2026-03-24 15:03:49'),(29,8,'Mililitro','ml',1.00,'receta',1,'2026-03-24 15:03:49'),(30,8,'Cucharadita','cdta',5.00,'receta',1,'2026-03-24 15:03:49'),(31,9,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(32,9,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(33,9,'Cucharada','cda',7.00,'receta',1,'2026-03-24 15:03:49'),(34,9,'Taza','taza',85.00,'receta',1,'2026-03-24 15:03:49'),(35,10,'Bolsa 500 g','bolsa',500.00,'compra',1,'2026-03-24 15:03:49'),(36,10,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(37,10,'Cucharadita','cdta',2.50,'receta',1,'2026-03-24 15:03:49'),(38,10,'Cucharada','cda',7.00,'receta',1,'2026-03-24 15:03:49'),(39,11,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(40,11,'Barra 190 g','barra',190.00,'compra',1,'2026-03-24 15:03:49'),(41,11,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(42,11,'Cucharada','cda',15.00,'receta',1,'2026-03-24 15:03:49'),(43,12,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(44,12,'Frasco 500 g','frasco',500.00,'compra',1,'2026-03-24 15:03:49'),(45,12,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(46,12,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(47,13,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(48,13,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(49,13,'Cucharada','cda',25.00,'receta',1,'2026-03-24 15:03:49'),(50,14,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(51,14,'Frasco 370 g','frasco',370.00,'compra',1,'2026-03-24 15:03:49'),(52,14,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(53,14,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(54,15,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(55,15,'Frasco 400 g','frasco',400.00,'compra',1,'2026-03-24 15:03:49'),(56,15,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(57,15,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(58,16,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(59,16,'Frasco 450 g','frasco',450.00,'compra',1,'2026-03-24 15:03:49'),(60,16,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(61,16,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(62,17,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(63,17,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(64,17,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(65,18,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(66,18,'Cono 250 g','cono',250.00,'compra',1,'2026-03-24 15:03:49'),(67,18,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(68,18,'Cucharada','cda',12.00,'receta',1,'2026-03-24 15:03:49'),(69,19,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(70,19,'Barra 250 g','barra',250.00,'compra',1,'2026-03-24 15:03:49'),(71,19,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(72,19,'Cucharada','cda',25.00,'receta',1,'2026-03-24 15:03:49'),(73,20,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(74,20,'Bolsa 500 g','bolsa',500.00,'compra',1,'2026-03-24 15:03:49'),(75,20,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(76,20,'Cucharada','cda',10.00,'receta',1,'2026-03-24 15:03:49'),(77,20,'Taza','taza',120.00,'receta',1,'2026-03-24 15:03:49');
/*!40000 ALTER TABLE `unidades_presentacion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios` (
  `id_usuario` int NOT NULL AUTO_INCREMENT,
  `uuid_usuario` varchar(36) NOT NULL,
  `nombre_completo` varchar(120) NOT NULL,
  `username` varchar(60) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `id_rol` smallint NOT NULL,
  `estatus` enum('activo','inactivo','bloqueado') NOT NULL,
  `intentos_fallidos` smallint NOT NULL,
  `bloqueado_hasta` datetime DEFAULT NULL,
  `ultimo_login` datetime DEFAULT NULL,
  `token_2fa` varchar(10) DEFAULT NULL,
  `token_2fa_expira` datetime DEFAULT NULL,
  `cambio_pwd_req` tinyint(1) NOT NULL,
  `creado_en` datetime NOT NULL,
  `actualizado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `uuid_usuario` (`uuid_usuario`),
  KEY `id_rol` (`id_rol`),
  KEY `creado_por` (`creado_por`),
  CONSTRAINT `usuarios_ibfk_2` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`),
  CONSTRAINT `usuarios_ibfk_3` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,'1313435b-27e3-4ecc-b4ca-6628dd75813a','Salvador Esquivel','esquivelsalvador260@gmail.com','scrypt:32768:8:1$662xtVgk2gBClqmN$881ce4f22cba6ee12a66e3660af7efb0a4027a24a32d188beceff3eb562a5f0033d9879b91c8194d403d2e878d7ffb1522af4aac068ad3b793f8999ed7f8724b',1,'activo',0,NULL,'2026-03-24 08:44:47',NULL,NULL,0,'2026-03-17 13:41:47','2026-03-24 08:44:47',NULL);
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_recetas_explosion`
--

DROP TABLE IF EXISTS `v_recetas_explosion`;
/*!50001 DROP VIEW IF EXISTS `v_recetas_explosion`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_recetas_explosion` AS SELECT 
 1 AS `producto`,
 1 AS `receta`,
 1 AS `rendimiento`,
 1 AS `unidad_rendimiento`,
 1 AS `insumo`,
 1 AS `cantidad_requerida`,
 1 AS `unidad_base`,
 1 AS `orden`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `ventas`
--

DROP TABLE IF EXISTS `ventas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ventas` (
  `id_venta` int NOT NULL AUTO_INCREMENT,
  `folio_venta` varchar(20) NOT NULL,
  `fecha_venta` datetime NOT NULL,
  `total` decimal(12,2) NOT NULL,
  `metodo_pago` enum('efectivo','tarjeta','transferencia','otro') NOT NULL,
  `cambio` decimal(10,2) DEFAULT NULL,
  `requiere_ticket` tinyint(1) NOT NULL,
  `estado` enum('abierta','completada','cancelada') NOT NULL,
  `vendedor_id` int NOT NULL,
  `id_corte` int DEFAULT NULL,
  `creado_en` datetime NOT NULL,
  PRIMARY KEY (`id_venta`),
  UNIQUE KEY `folio_venta` (`folio_venta`),
  KEY `id_corte` (`id_corte`),
  KEY `vendedor_id` (`vendedor_id`),
  CONSTRAINT `ventas_ibfk_1` FOREIGN KEY (`id_corte`) REFERENCES `cortes_diarios` (`id_corte`) ON DELETE SET NULL,
  CONSTRAINT `ventas_ibfk_2` FOREIGN KEY (`vendedor_id`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ventas`
--

LOCK TABLES `ventas` WRITE;
/*!40000 ALTER TABLE `ventas` DISABLE KEYS */;
/*!40000 ALTER TABLE `ventas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Final view structure for view `v_recetas_explosion`
--

/*!50001 DROP VIEW IF EXISTS `v_recetas_explosion`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_recetas_explosion` AS select `pt`.`nombre` AS `producto`,`r`.`nombre` AS `receta`,`r`.`rendimiento` AS `rendimiento`,`r`.`unidad_rendimiento` AS `unidad_rendimiento`,`mp`.`nombre` AS `insumo`,`dr`.`cantidad_requerida` AS `cantidad_requerida`,`mp`.`unidad_base` AS `unidad_base`,`dr`.`orden` AS `orden` from (((`detalle_recetas` `dr` join `recetas` `r` on((`r`.`id_receta` = `dr`.`id_receta`))) join `productos_terminados` `pt` on((`pt`.`id_producto` = `r`.`id_producto`))) join `materias_primas` `mp` on((`mp`.`id_materia` = `dr`.`id_materia`))) order by `pt`.`nombre`,`r`.`rendimiento`,`dr`.`orden` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-03-24 19:10:08
