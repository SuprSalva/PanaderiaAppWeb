CREATE DATABASE  IF NOT EXISTS `dulce_migaja` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `dulce_migaja`;
-- MySQL dump 10.13  Distrib 8.0.31, for Win64 (x86_64)
--
-- Host: localhost    Database: dulce_migaja
-- ------------------------------------------------------
-- Server version	8.0.31

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
-- Table structure for table `caja_productos`
--

DROP TABLE IF EXISTS `caja_productos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `caja_productos` (
  `id_caja_producto` int NOT NULL AUTO_INCREMENT,
  `id_caja` int NOT NULL,
  `id_producto` int NOT NULL COMMENT 'FK a productos (pan terminado)',
  `cantidad` tinyint NOT NULL COMMENT 'Piezas de este producto en la caja',
  PRIMARY KEY (`id_caja_producto`),
  UNIQUE KEY `uq_caja_prod` (`id_caja`,`id_producto`),
  KEY `fk_cajaprod_caja` (`id_caja`),
  KEY `fk_cajaprod_producto` (`id_producto`),
  CONSTRAINT `fk_cajaprod_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON DELETE CASCADE,
  CONSTRAINT `fk_cajaprod_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Composición de cada caja: qué productos lleva y cuántas piezas.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `caja_productos`
--

LOCK TABLES `caja_productos` WRITE;
/*!40000 ALTER TABLE `caja_productos` DISABLE KEYS */;
/*!40000 ALTER TABLE `caja_productos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cajas`
--

DROP TABLE IF EXISTS `cajas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cajas` (
  `id_caja` int NOT NULL AUTO_INCREMENT,
  `uuid_caja` varchar(36) NOT NULL,
  `nombre` varchar(120) NOT NULL COMMENT 'Ej: Caja Mixta Concha+Dona Chica',
  `descripcion` text,
  `id_tamanio` int NOT NULL COMMENT 'FK a tamanios_charola',
  `tipo` enum('simple','mixta','triple') NOT NULL DEFAULT 'simple' COMMENT 'simple = 1 tipo; mixta = 2 tipos; triple = 3 tipos (solo charola grande)',
  `precio_venta` decimal(10,2) NOT NULL DEFAULT '0.00',
  `estatus` enum('activo','inactivo') NOT NULL DEFAULT 'activo',
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_caja`),
  UNIQUE KEY `uq_uuid_caja` (`uuid_caja`),
  KEY `fk_caja_tamanio` (`id_tamanio`),
  KEY `fk_caja_creado_por` (`creado_por`),
  CONSTRAINT `fk_caja_creado_por` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `fk_caja_tamanio` FOREIGN KEY (`id_tamanio`) REFERENCES `tamanios_charola` (`id_tamanio`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Catálogo de cajas de pan disponibles para venta.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cajas`
--

LOCK TABLES `cajas` WRITE;
/*!40000 ALTER TABLE `cajas` DISABLE KEYS */;
/*!40000 ALTER TABLE `cajas` ENABLE KEYS */;
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
  `folio_factura` varchar(60) DEFAULT NULL,
  `id_proveedor` int NOT NULL,
  `fecha_compra` date NOT NULL,
  `total` decimal(12,2) NOT NULL,
  `estatus` enum('ordenado','cancelado','finalizado') NOT NULL DEFAULT 'ordenado',
  `motivo_cancelacion` text,
  `observaciones` text,
  `creado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_compra`),
  UNIQUE KEY `folio` (`folio`),
  KEY `id_proveedor` (`id_proveedor`),
  KEY `creado_por` (`creado_por`),
  CONSTRAINT `compras_ibfk_2` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedores` (`id_proveedor`),
  CONSTRAINT `compras_ibfk_3` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `compras`
--

LOCK TABLES `compras` WRITE;
/*!40000 ALTER TABLE `compras` DISABLE KEYS */;
INSERT INTO `compras` VALUES (1,'C-0001','FAC-2026-03-31-A',1,'2026-04-06',254.00,'finalizado',NULL,NULL,'2026-03-31 15:21:40',1),(2,'C-0002','FAC-2026-04-06-B',2,'2026-04-06',205.00,'finalizado',NULL,NULL,'2026-04-06 19:20:43',1),(3,'C-0003','FAC-2026-04-06-C',1,'2026-04-06',4385.00,'finalizado',NULL,NULL,'2026-04-06 19:32:28',1),(4,'C-0004','FAC-2026-04-09-A',1,'2026-04-09',84.00,'finalizado',NULL,NULL,'2026-04-09 11:29:03',1);
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
  `efectivo_declarado` decimal(12,2) DEFAULT '0.00',
  `diferencia_efectivo` decimal(12,2) DEFAULT '0.00',
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
  KEY `idx_cortes_estado_fecha` (`estado`,`fecha_corte`),
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
  KEY `id_unidad_presentacion` (`id_unidad_presentacion`),
  KEY `idx_det_compras_materia_fecha` (`id_materia`,`id_compra`),
  CONSTRAINT `detalle_compras_ibfk_1` FOREIGN KEY (`id_compra`) REFERENCES `compras` (`id_compra`) ON DELETE CASCADE,
  CONSTRAINT `detalle_compras_ibfk_2` FOREIGN KEY (`id_materia`) REFERENCES `materias_primas` (`id_materia`),
  CONSTRAINT `detalle_compras_ibfk_3` FOREIGN KEY (`id_unidad_presentacion`) REFERENCES `unidades_presentacion` (`id_unidad`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_compras`
--

LOCK TABLES `detalle_compras` WRITE;
/*!40000 ALTER TABLE `detalle_compras` DISABLE KEYS */;
INSERT INTO `detalle_compras` VALUES (1,1,20,12.0000,'bolsa',500.0000,6000.0000,10.0000,74),(2,1,4,3.0000,'lt',1000.0000,3000.0000,37.0000,14),(3,1,8,1.0000,'lt',1000.0000,1000.0000,23.0000,28),(4,2,6,1.0000,'kg',16.0000,16.0000,40.0000,20),(5,2,12,1.0000,'kg',1000.0000,1000.0000,120.0000,43),(6,2,16,1.0000,'frasco',450.0000,450.0000,45.0000,59),(7,3,20,3.0000,'kg',1000.0000,3000.0000,55.0000,73),(8,3,2,5.0000,'kg',1000.0000,5000.0000,42.0000,5),(9,3,21,30.0000,'pza',1.0000,30.0000,3.0000,NULL),(10,3,23,30.0000,'pza',1.0000,30.0000,6.0000,NULL),(11,3,22,30.0000,'pza',1.0000,30.0000,5.0000,NULL),(12,3,10,1.0000,'bolsa',500.0000,500.0000,50.0000,35),(13,3,9,1.0000,'kg',1000.0000,1000.0000,300.0000,31),(14,3,15,3.0000,'frasco',400.0000,1200.0000,73.0000,55),(15,3,17,1.0000,'frasc250',250.0000,250.0000,255.0000,79),(16,3,13,2.0000,'kg',1000.0000,2000.0000,84.0000,47),(17,3,16,1.0000,'frasco',450.0000,450.0000,45.0000,59),(18,3,8,1.0000,'lt',1000.0000,1000.0000,195.0000,28),(19,3,1,10.0000,'kg',1000.0000,10000.0000,27.0000,1),(20,3,4,5.0000,'lt',1000.0000,5000.0000,28.0000,14),(21,3,5,2.0000,'kg',1000.0000,2000.0000,150.0000,17),(22,3,3,2.0000,'kg',1000.0000,2000.0000,300.0000,9),(23,3,14,2.0000,'kg',1000.0000,2000.0000,98.0000,50),(24,3,18,4.0000,'kg',1000.0000,4000.0000,85.0000,65),(25,3,11,4.0000,'barra',190.0000,760.0000,48.0000,40),(26,3,19,8.0000,'barra',250.0000,2000.0000,40.0000,70),(27,4,6,2.0000,'caja',30.0000,60.0000,42.0000,22);
/*!40000 ALTER TABLE `detalle_compras` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `detalle_pedidos`
--

DROP TABLE IF EXISTS `detalle_pedidos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `detalle_pedidos` (
  `id_detalle` int NOT NULL AUTO_INCREMENT,
  `id_pedido` int NOT NULL,
  `id_producto` int NOT NULL,
  `cantidad` decimal(10,2) NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL COMMENT 'Precio al momento del pedido',
  `subtotal` decimal(12,2) NOT NULL,
  PRIMARY KEY (`id_detalle`),
  KEY `fk_detped_pedido` (`id_pedido`),
  KEY `fk_detped_producto` (`id_producto`),
  KEY `idx_detped_pedido` (`id_pedido`),
  KEY `idx_detped_pedido_producto` (`id_pedido`,`id_producto`),
  CONSTRAINT `fk_detped_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`) ON DELETE CASCADE,
  CONSTRAINT `fk_detped_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE RESTRICT
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Líneas de productos dentro de un pedido';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_pedidos`
--

LOCK TABLES `detalle_pedidos` WRITE;
/*!40000 ALTER TABLE `detalle_pedidos` DISABLE KEYS */;
INSERT INTO `detalle_pedidos` VALUES (36,12,12,6.00,20.00,120.00),(37,12,10,6.00,22.00,132.00),(38,13,4,4.00,28.00,112.00),(39,14,1,4.00,24.00,96.00),(40,14,2,4.00,26.00,104.00),(41,14,4,4.00,28.00,112.00),(42,15,1,3.00,24.00,72.00),(43,16,1,3.00,24.00,72.00);
/*!40000 ALTER TABLE `detalle_pedidos` ENABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=202 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_produccion`
--

LOCK TABLES `detalle_produccion` WRITE;
/*!40000 ALTER TABLE `detalle_produccion` DISABLE KEYS */;
INSERT INTO `detalle_produccion` VALUES (157,16,1,540.0000,540.0000),(158,16,2,90.0000,90.0000),(159,16,3,155.0000,155.0000),(160,16,4,130.0000,130.0000),(161,16,5,10.0000,10.0000),(162,16,6,125.0000,125.0000),(163,16,7,6.0000,6.0000),(164,16,8,5.0000,5.0000),(165,16,20,70.0000,70.0000),(166,16,14,120.0000,120.0000),(172,17,1,150.0000,150.0000),(173,17,2,33.3333,33.3333),(174,17,3,20.0000,20.0000),(175,17,4,53.3333,53.3333),(176,17,5,2.6667,2.6667),(177,17,6,33.3333,33.3333),(178,17,7,2.0000,2.0000),(179,17,9,10.0000,10.0000),(180,17,15,83.3333,83.3333),(187,18,1,476.6667,476.6667),(188,18,2,113.3333,113.3333),(189,18,3,76.6667,76.6667),(190,18,4,153.3333,153.3333),(191,18,5,8.0000,8.0000),(192,18,6,10.0000,10.0000),(193,18,7,6.0000,6.0000),(194,18,8,2.0000,2.0000),(195,18,13,146.6667,146.6667),(196,18,9,26.6667,26.6667),(197,18,15,83.3333,83.3333);
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
  `cantidad_requerida` decimal(10,2) DEFAULT NULL,
  `orden` smallint NOT NULL,
  `id_unidad_presentacion` int DEFAULT NULL,
  `cantidad_presentacion` decimal(12,4) DEFAULT NULL,
  PRIMARY KEY (`id_detalle_receta`),
  UNIQUE KEY `uq_det_receta_materia` (`id_receta`,`id_materia`),
  KEY `id_materia` (`id_materia`),
  KEY `id_unidad_presentacion` (`id_unidad_presentacion`),
  KEY `idx_det_recetas_id_receta` (`id_receta`),
  CONSTRAINT `detalle_recetas_ibfk_1` FOREIGN KEY (`id_materia`) REFERENCES `materias_primas` (`id_materia`),
  CONSTRAINT `detalle_recetas_ibfk_2` FOREIGN KEY (`id_receta`) REFERENCES `recetas` (`id_receta`) ON DELETE CASCADE,
  CONSTRAINT `detalle_recetas_ibfk_3` FOREIGN KEY (`id_unidad_presentacion`) REFERENCES `unidades_presentacion` (`id_unidad`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=596 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_recetas`
--

LOCK TABLES `detalle_recetas` WRITE;
/*!40000 ALTER TABLE `detalle_recetas` DISABLE KEYS */;
INSERT INTO `detalle_recetas` VALUES (136,17,1,167.00,1,NULL,NULL),(137,17,2,40.00,2,NULL,NULL),(138,17,3,27.00,3,NULL,NULL),(139,17,4,50.00,4,NULL,NULL),(140,17,6,3.00,5,NULL,NULL),(141,17,5,3.00,6,NULL,NULL),(142,17,7,2.00,7,NULL,NULL),(143,17,8,2.00,8,NULL,NULL),(144,17,13,80.00,9,NULL,NULL),(145,17,21,1.00,10,NULL,NULL),(146,18,1,333.00,1,NULL,NULL),(147,18,2,80.00,2,NULL,NULL),(148,18,3,53.00,3,NULL,NULL),(149,18,4,100.00,4,NULL,NULL),(150,18,6,6.00,5,NULL,NULL),(151,18,5,5.00,6,NULL,NULL),(152,18,7,3.00,7,NULL,NULL),(153,18,8,3.00,8,NULL,NULL),(154,18,13,160.00,9,NULL,NULL),(155,18,22,1.00,10,NULL,NULL),(156,19,1,500.00,1,NULL,NULL),(157,19,2,120.00,2,NULL,NULL),(158,19,3,80.00,3,NULL,NULL),(159,19,4,150.00,4,NULL,NULL),(160,19,6,10.00,5,NULL,NULL),(161,19,5,8.00,6,NULL,NULL),(162,19,7,5.00,7,NULL,NULL),(163,19,8,5.00,8,NULL,NULL),(164,19,13,240.00,9,NULL,NULL),(165,19,23,1.00,10,NULL,NULL),(166,20,1,160.00,1,NULL,NULL),(167,20,2,40.00,2,NULL,NULL),(168,20,3,30.00,3,NULL,NULL),(169,20,4,50.00,4,NULL,NULL),(170,20,5,3.00,5,NULL,NULL),(171,20,6,3.00,6,NULL,NULL),(172,20,7,2.00,7,NULL,NULL),(173,20,9,17.00,8,NULL,NULL),(174,20,13,67.00,9,NULL,NULL),(175,20,21,1.00,10,NULL,NULL),(176,21,1,320.00,1,NULL,NULL),(177,21,2,80.00,2,NULL,NULL),(178,21,3,60.00,3,NULL,NULL),(179,21,4,100.00,4,NULL,NULL),(180,21,5,5.00,5,NULL,NULL),(181,21,6,6.00,6,NULL,NULL),(182,21,7,3.00,7,NULL,NULL),(183,21,9,33.00,8,NULL,NULL),(184,21,13,133.00,9,NULL,NULL),(185,21,22,1.00,10,NULL,NULL),(186,22,1,480.00,1,NULL,NULL),(187,22,2,120.00,2,NULL,NULL),(188,22,3,90.00,3,NULL,NULL),(189,22,4,150.00,4,NULL,NULL),(190,22,5,8.00,5,NULL,NULL),(191,22,6,10.00,6,NULL,NULL),(192,22,7,5.00,7,NULL,NULL),(193,22,9,50.00,8,NULL,NULL),(194,22,13,200.00,9,NULL,NULL),(195,22,23,1.00,10,NULL,NULL),(196,23,1,183.00,1,NULL,NULL),(197,23,2,27.00,2,NULL,NULL),(198,23,3,67.00,3,NULL,NULL),(199,23,4,40.00,4,NULL,NULL),(200,23,6,3.00,5,NULL,NULL),(201,23,5,3.00,6,NULL,NULL),(202,23,7,2.00,7,NULL,NULL),(203,23,12,70.00,8,NULL,NULL),(204,23,11,70.00,9,NULL,NULL),(205,23,21,1.00,10,NULL,NULL),(206,24,1,367.00,1,NULL,NULL),(207,24,2,53.00,2,NULL,NULL),(208,24,3,133.00,3,NULL,NULL),(209,24,4,80.00,4,NULL,NULL),(210,24,6,6.00,5,NULL,NULL),(211,24,5,5.00,6,NULL,NULL),(212,24,7,4.00,7,NULL,NULL),(213,24,12,140.00,8,NULL,NULL),(214,24,11,140.00,9,NULL,NULL),(215,24,22,1.00,10,NULL,NULL),(216,25,1,550.00,1,NULL,NULL),(217,25,2,80.00,2,NULL,NULL),(218,25,3,200.00,3,NULL,NULL),(219,25,4,120.00,4,NULL,NULL),(220,25,6,10.00,5,NULL,NULL),(221,25,5,8.00,6,NULL,NULL),(222,25,7,6.00,7,NULL,NULL),(223,25,12,210.00,8,NULL,NULL),(224,25,11,210.00,9,NULL,NULL),(225,25,23,1.00,10,NULL,NULL),(226,26,1,150.00,1,NULL,NULL),(227,26,2,33.00,2,NULL,NULL),(228,26,3,20.00,3,NULL,NULL),(229,26,4,53.00,4,NULL,NULL),(230,26,6,3.00,5,NULL,NULL),(231,26,5,3.00,6,NULL,NULL),(232,26,7,2.00,7,NULL,NULL),(233,26,9,10.00,8,NULL,NULL),(234,26,15,83.00,9,NULL,NULL),(235,26,21,1.00,10,NULL,NULL),(236,27,1,300.00,1,NULL,NULL),(237,27,2,67.00,2,NULL,NULL),(238,27,3,40.00,3,NULL,NULL),(239,27,4,107.00,4,NULL,NULL),(240,27,6,6.00,5,NULL,NULL),(241,27,5,5.00,6,NULL,NULL),(242,27,7,3.00,7,NULL,NULL),(243,27,9,20.00,8,NULL,NULL),(244,27,15,167.00,9,NULL,NULL),(245,27,22,1.00,10,NULL,NULL),(246,28,1,450.00,1,NULL,NULL),(247,28,2,100.00,2,NULL,NULL),(248,28,3,60.00,3,NULL,NULL),(249,28,4,160.00,4,NULL,NULL),(250,28,6,10.00,5,NULL,NULL),(251,28,5,8.00,6,NULL,NULL),(252,28,7,5.00,7,NULL,NULL),(253,28,9,30.00,8,NULL,NULL),(254,28,15,250.00,9,NULL,NULL),(255,28,23,1.00,10,NULL,NULL),(256,29,1,183.00,1,NULL,NULL),(257,29,2,23.00,2,NULL,NULL),(258,29,3,67.00,3,NULL,NULL),(259,29,4,40.00,4,NULL,NULL),(260,29,6,3.00,5,NULL,NULL),(261,29,5,3.00,6,NULL,NULL),(262,29,7,2.00,7,NULL,NULL),(263,29,16,93.00,8,NULL,NULL),(264,29,21,1.00,9,NULL,NULL),(265,30,1,367.00,1,NULL,NULL),(266,30,2,47.00,2,NULL,NULL),(267,30,3,133.00,3,NULL,NULL),(268,30,4,80.00,4,NULL,NULL),(269,30,6,6.00,5,NULL,NULL),(270,30,5,5.00,6,NULL,NULL),(271,30,7,4.00,7,NULL,NULL),(272,30,16,187.00,8,NULL,NULL),(273,30,22,1.00,9,NULL,NULL),(274,31,1,550.00,1,NULL,NULL),(275,31,2,70.00,2,NULL,NULL),(276,31,3,200.00,3,NULL,NULL),(277,31,4,120.00,4,NULL,NULL),(278,31,6,10.00,5,NULL,NULL),(279,31,5,8.00,6,NULL,NULL),(280,31,7,6.00,7,NULL,NULL),(281,31,16,280.00,8,NULL,NULL),(282,31,23,1.00,9,NULL,NULL),(283,32,1,133.00,1,NULL,NULL),(284,32,2,27.00,2,NULL,NULL),(285,32,3,60.00,3,NULL,NULL),(286,32,6,2.00,4,NULL,NULL),(287,32,7,1.00,5,NULL,NULL),(288,32,8,1.00,6,NULL,NULL),(289,32,20,17.00,7,NULL,NULL),(290,32,17,67.00,8,NULL,NULL),(291,32,21,1.00,9,NULL,NULL),(292,33,1,267.00,1,NULL,NULL),(293,33,2,53.00,2,NULL,NULL),(294,33,3,120.00,3,NULL,NULL),(295,33,6,4.00,4,NULL,NULL),(296,33,7,2.00,5,NULL,NULL),(297,33,8,3.00,6,NULL,NULL),(298,33,20,33.00,7,NULL,NULL),(299,33,17,133.00,8,NULL,NULL),(300,33,22,1.00,9,NULL,NULL),(301,34,1,400.00,1,NULL,NULL),(302,34,2,80.00,2,NULL,NULL),(303,34,3,180.00,3,NULL,NULL),(304,34,6,6.00,4,NULL,NULL),(305,34,7,3.00,5,NULL,NULL),(306,34,8,4.00,6,NULL,NULL),(307,34,20,50.00,7,NULL,NULL),(308,34,17,200.00,8,NULL,NULL),(309,34,23,1.00,9,NULL,NULL),(310,35,1,167.00,1,NULL,NULL),(311,35,2,20.00,2,NULL,NULL),(312,35,3,27.00,3,NULL,NULL),(313,35,4,60.00,4,NULL,NULL),(314,35,6,2.00,5,NULL,NULL),(315,35,5,3.00,6,NULL,NULL),(316,35,7,2.00,7,NULL,NULL),(317,35,10,5.00,8,NULL,NULL),(318,35,18,67.00,9,NULL,NULL),(319,35,21,1.00,10,NULL,NULL),(320,36,1,333.00,1,NULL,NULL),(321,36,2,40.00,2,NULL,NULL),(322,36,3,53.00,3,NULL,NULL),(323,36,4,120.00,4,NULL,NULL),(324,36,6,5.00,5,NULL,NULL),(325,36,5,7.00,6,NULL,NULL),(326,36,7,4.00,7,NULL,NULL),(327,36,10,10.00,8,NULL,NULL),(328,36,18,133.00,9,NULL,NULL),(329,36,22,1.00,10,NULL,NULL),(330,37,1,500.00,1,NULL,NULL),(331,37,2,60.00,2,NULL,NULL),(332,37,3,80.00,3,NULL,NULL),(333,37,4,180.00,4,NULL,NULL),(334,37,6,8.00,5,NULL,NULL),(335,37,5,10.00,6,NULL,NULL),(336,37,7,6.00,7,NULL,NULL),(337,37,10,15.00,8,NULL,NULL),(338,37,18,200.00,9,NULL,NULL),(339,37,23,1.00,10,NULL,NULL),(340,38,1,100.00,1,NULL,NULL),(341,38,9,27.00,2,NULL,NULL),(342,38,2,40.00,3,NULL,NULL),(343,38,3,50.00,4,NULL,NULL),(344,38,6,6.00,5,NULL,NULL),(345,38,7,1.00,6,NULL,NULL),(346,38,13,50.00,7,NULL,NULL),(347,38,21,1.00,8,NULL,NULL),(348,39,1,200.00,1,NULL,NULL),(349,39,9,53.00,2,NULL,NULL),(350,39,2,80.00,3,NULL,NULL),(351,39,3,100.00,4,NULL,NULL),(352,39,6,3.00,5,NULL,NULL),(353,39,7,2.00,6,NULL,NULL),(354,39,13,100.00,7,NULL,NULL),(355,39,22,1.00,8,NULL,NULL),(356,40,1,300.00,1,NULL,NULL),(357,40,9,80.00,2,NULL,NULL),(358,40,2,120.00,3,NULL,NULL),(359,40,3,150.00,4,NULL,NULL),(360,40,6,20.00,5,NULL,NULL),(361,40,7,3.00,6,NULL,NULL),(362,40,13,150.00,7,NULL,NULL),(363,40,23,1.00,8,NULL,NULL),(364,41,1,167.00,1,NULL,NULL),(365,41,2,27.00,2,NULL,NULL),(366,41,3,20.00,3,NULL,NULL),(367,41,4,53.00,4,NULL,NULL),(368,41,6,3.00,5,NULL,NULL),(369,41,5,3.00,6,NULL,NULL),(370,41,7,2.00,7,NULL,NULL),(371,41,8,2.00,8,NULL,NULL),(372,41,19,80.00,9,NULL,NULL),(373,41,21,1.00,10,NULL,NULL),(374,42,1,333.00,1,NULL,NULL),(375,42,2,53.00,2,NULL,NULL),(376,42,3,40.00,3,NULL,NULL),(377,42,4,107.00,4,NULL,NULL),(378,42,6,6.00,5,NULL,NULL),(379,42,5,5.00,6,NULL,NULL),(380,42,7,3.00,7,NULL,NULL),(381,42,8,4.00,8,NULL,NULL),(382,42,19,160.00,9,NULL,NULL),(383,42,22,1.00,10,NULL,NULL),(384,43,1,500.00,1,NULL,NULL),(385,43,2,80.00,2,NULL,NULL),(386,43,3,60.00,3,NULL,NULL),(387,43,4,160.00,4,NULL,NULL),(388,43,6,10.00,5,NULL,NULL),(389,43,5,8.00,6,NULL,NULL),(390,43,7,5.00,7,NULL,NULL),(391,43,8,6.00,8,NULL,NULL),(392,43,19,240.00,9,NULL,NULL),(393,43,23,1.00,10,NULL,NULL),(394,44,1,160.00,1,NULL,NULL),(395,44,2,33.00,2,NULL,NULL),(396,44,3,20.00,3,NULL,NULL),(397,44,4,53.00,4,NULL,NULL),(398,44,6,3.00,5,NULL,NULL),(399,44,5,3.00,6,NULL,NULL),(400,44,7,2.00,7,NULL,NULL),(401,44,8,1.00,8,NULL,NULL),(402,44,20,20.00,9,NULL,NULL),(403,44,14,80.00,10,NULL,NULL),(404,44,21,1.00,11,NULL,NULL),(405,45,1,320.00,1,NULL,NULL),(406,45,2,67.00,2,NULL,NULL),(407,45,3,40.00,3,NULL,NULL),(408,45,4,107.00,4,NULL,NULL),(409,45,6,6.00,5,NULL,NULL),(410,45,5,7.00,6,NULL,NULL),(411,45,7,3.00,7,NULL,NULL),(412,45,8,3.00,8,NULL,NULL),(413,45,20,40.00,9,NULL,NULL),(414,45,14,160.00,10,NULL,NULL),(415,45,22,1.00,11,NULL,NULL),(416,46,1,480.00,1,NULL,NULL),(417,46,2,100.00,2,NULL,NULL),(418,46,3,60.00,3,NULL,NULL),(419,46,4,160.00,4,NULL,NULL),(420,46,6,10.00,5,NULL,NULL),(421,46,5,10.00,6,NULL,NULL),(422,46,7,5.00,7,NULL,NULL),(423,46,8,4.00,8,NULL,NULL),(424,46,20,60.00,9,NULL,NULL),(425,46,14,240.00,10,NULL,NULL),(426,46,23,1.00,11,NULL,NULL),(427,47,1,173.00,1,NULL,NULL),(428,47,2,27.00,2,NULL,NULL),(429,47,3,67.00,3,NULL,NULL),(430,47,4,40.00,4,NULL,NULL),(431,47,6,3.00,5,NULL,NULL),(432,47,5,3.00,6,NULL,NULL),(433,47,7,2.00,7,NULL,NULL),(434,47,8,1.00,8,NULL,NULL),(435,47,13,50.00,9,NULL,NULL),(436,47,14,40.00,10,NULL,NULL),(437,47,21,1.00,11,NULL,NULL),(438,48,1,347.00,1,NULL,NULL),(439,48,2,53.00,2,NULL,NULL),(440,48,3,133.00,3,NULL,NULL),(441,48,4,80.00,4,NULL,NULL),(442,48,6,7.00,5,NULL,NULL),(443,48,5,5.00,6,NULL,NULL),(444,48,7,4.00,7,NULL,NULL),(445,48,8,3.00,8,NULL,NULL),(446,48,13,100.00,9,NULL,NULL),(447,48,14,80.00,10,NULL,NULL),(448,48,22,1.00,11,NULL,NULL),(449,49,1,520.00,1,NULL,NULL),(450,49,2,80.00,2,NULL,NULL),(451,49,3,200.00,3,NULL,NULL),(452,49,4,120.00,4,NULL,NULL),(453,49,6,10.00,5,NULL,NULL),(454,49,5,8.00,6,NULL,NULL),(455,49,7,6.00,7,NULL,NULL),(456,49,8,4.00,8,NULL,NULL),(457,49,13,150.00,9,NULL,NULL),(458,49,14,120.00,10,NULL,NULL),(459,49,23,1.00,11,NULL,NULL),(460,50,1,200.00,1,NULL,NULL),(461,50,2,27.00,2,NULL,NULL),(462,50,3,83.00,3,NULL,NULL),(463,50,4,33.00,4,NULL,NULL),(464,50,6,5.00,5,NULL,NULL),(465,50,5,3.00,6,NULL,NULL),(466,50,7,2.00,7,NULL,NULL),(467,50,8,2.00,8,NULL,NULL),(468,50,20,27.00,9,NULL,NULL),(469,50,21,1.00,10,NULL,NULL),(470,51,1,400.00,1,NULL,NULL),(471,51,2,53.00,2,NULL,NULL),(472,51,3,167.00,3,NULL,NULL),(473,51,4,67.00,4,NULL,NULL),(474,51,6,10.00,5,NULL,NULL),(475,51,5,7.00,6,NULL,NULL),(476,51,7,4.00,7,NULL,NULL),(477,51,8,3.00,8,NULL,NULL),(478,51,20,53.00,9,NULL,NULL),(479,51,22,1.00,10,NULL,NULL),(480,52,1,600.00,1,NULL,NULL),(481,52,2,80.00,2,NULL,NULL),(482,52,3,250.00,3,NULL,NULL),(483,52,4,100.00,4,NULL,NULL),(484,52,6,15.00,5,NULL,NULL),(485,52,5,10.00,6,NULL,NULL),(486,52,7,6.00,7,NULL,NULL),(487,52,8,5.00,8,NULL,NULL),(488,52,20,80.00,9,NULL,NULL),(489,52,23,1.00,10,NULL,NULL),(490,53,1,250.00,1,NULL,NULL),(491,53,2,60.00,2,NULL,NULL),(492,53,3,40.00,3,NULL,NULL),(493,53,4,75.00,4,NULL,NULL),(494,53,6,5.00,5,NULL,NULL),(495,53,5,4.00,6,NULL,NULL),(496,53,7,3.00,7,NULL,NULL),(497,53,8,3.00,8,NULL,NULL),(498,53,13,120.00,9,NULL,NULL),(499,54,1,240.00,1,NULL,NULL),(500,54,2,60.00,2,NULL,NULL),(501,54,3,45.00,3,NULL,NULL),(502,54,4,75.00,4,NULL,NULL),(503,54,5,4.00,5,NULL,NULL),(504,54,6,5.00,6,NULL,NULL),(505,54,7,3.00,7,NULL,NULL),(506,54,9,25.00,8,NULL,NULL),(507,54,13,100.00,9,NULL,NULL),(508,55,1,275.00,1,NULL,NULL),(509,55,2,40.00,2,NULL,NULL),(510,55,3,100.00,3,NULL,NULL),(511,55,4,60.00,4,NULL,NULL),(512,55,6,5.00,5,NULL,NULL),(513,55,5,4.00,6,NULL,NULL),(514,55,7,3.00,7,NULL,NULL),(515,55,12,105.00,8,NULL,NULL),(516,55,11,105.00,9,NULL,NULL),(517,56,1,225.00,1,NULL,NULL),(518,56,2,50.00,2,NULL,NULL),(519,56,3,30.00,3,NULL,NULL),(520,56,4,80.00,4,NULL,NULL),(521,56,6,5.00,5,NULL,NULL),(522,56,5,4.00,6,NULL,NULL),(523,56,7,3.00,7,NULL,NULL),(524,56,9,15.00,8,NULL,NULL),(525,56,15,125.00,9,NULL,NULL),(526,57,1,275.00,1,NULL,NULL),(527,57,2,35.00,2,NULL,NULL),(528,57,3,100.00,3,NULL,NULL),(529,57,4,60.00,4,NULL,NULL),(530,57,6,5.00,5,NULL,NULL),(531,57,5,4.00,6,NULL,NULL),(532,57,7,3.00,7,NULL,NULL),(533,57,16,140.00,8,NULL,NULL),(534,58,1,200.00,1,NULL,NULL),(535,58,2,40.00,2,NULL,NULL),(536,58,3,90.00,3,NULL,NULL),(537,58,6,3.00,4,NULL,NULL),(538,58,7,2.00,5,NULL,NULL),(539,58,8,2.00,6,NULL,NULL),(540,58,20,25.00,7,NULL,NULL),(541,58,17,100.00,8,NULL,NULL),(542,59,1,250.00,1,NULL,NULL),(543,59,2,30.00,2,NULL,NULL),(544,59,3,40.00,3,NULL,NULL),(545,59,4,90.00,4,NULL,NULL),(546,59,6,4.00,5,NULL,NULL),(547,59,5,5.00,6,NULL,NULL),(548,59,7,3.00,7,NULL,NULL),(549,59,10,8.00,8,NULL,NULL),(550,59,18,100.00,9,NULL,NULL),(551,60,1,150.00,1,NULL,NULL),(552,60,9,40.00,2,NULL,NULL),(553,60,2,60.00,3,NULL,NULL),(554,60,3,75.00,4,NULL,NULL),(555,60,6,10.00,5,NULL,NULL),(556,60,7,2.00,6,NULL,NULL),(557,60,13,75.00,7,NULL,NULL),(558,61,1,250.00,1,NULL,NULL),(559,61,2,40.00,2,NULL,NULL),(560,61,3,30.00,3,NULL,NULL),(561,61,4,80.00,4,NULL,NULL),(562,61,6,5.00,5,NULL,NULL),(563,61,5,4.00,6,NULL,NULL),(564,61,7,3.00,7,NULL,NULL),(565,61,8,3.00,8,NULL,NULL),(566,61,19,120.00,9,NULL,NULL),(567,62,1,240.00,1,NULL,NULL),(568,62,2,50.00,2,NULL,NULL),(569,62,3,30.00,3,NULL,NULL),(570,62,4,80.00,4,NULL,NULL),(571,62,6,5.00,5,NULL,NULL),(572,62,5,5.00,6,NULL,NULL),(573,62,7,3.00,7,NULL,NULL),(574,62,8,2.00,8,NULL,NULL),(575,62,20,30.00,9,NULL,NULL),(576,62,14,120.00,10,NULL,NULL),(577,63,1,260.00,1,NULL,NULL),(578,63,2,40.00,2,NULL,NULL),(579,63,3,100.00,3,NULL,NULL),(580,63,4,60.00,4,NULL,NULL),(581,63,6,5.00,5,NULL,NULL),(582,63,5,4.00,6,NULL,NULL),(583,63,7,3.00,7,NULL,NULL),(584,63,8,2.00,8,NULL,NULL),(585,63,13,75.00,9,NULL,NULL),(586,63,14,60.00,10,NULL,NULL),(587,64,1,300.00,1,NULL,NULL),(588,64,2,40.00,2,NULL,NULL),(589,64,3,125.00,3,NULL,NULL),(590,64,4,50.00,4,NULL,NULL),(591,64,6,7.00,5,NULL,NULL),(592,64,5,5.00,6,NULL,NULL),(593,64,7,3.00,7,NULL,NULL),(594,64,8,3.00,8,NULL,NULL),(595,64,20,40.00,9,NULL,NULL);
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
  `id_producto` int DEFAULT NULL COMMENT 'Producto suelto vendido. NULL cuando la venta es una caja.',
  `cantidad` decimal(10,2) NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  `descuento_pct` decimal(5,2) NOT NULL,
  `subtotal` decimal(12,2) NOT NULL,
  `id_caja` int DEFAULT NULL COMMENT 'Caja vendida. NULL = venta de pieza suelta.',
  PRIMARY KEY (`id_detalle_venta`),
  KEY `fk_detventa_producto` (`id_producto`),
  KEY `fk_detventa_caja` (`id_caja`),
  KEY `idx_dv_venta_producto` (`id_venta`,`id_producto`),
  CONSTRAINT `detalle_ventas_ibfk_2` FOREIGN KEY (`id_venta`) REFERENCES `ventas` (`id_venta`) ON DELETE CASCADE,
  CONSTRAINT `fk_detventa_caja` FOREIGN KEY (`id_caja`) REFERENCES `cajas` (`id_caja`) ON DELETE SET NULL,
  CONSTRAINT `fk_detventa_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `detalle_ventas`
--

LOCK TABLES `detalle_ventas` WRITE;
/*!40000 ALTER TABLE `detalle_ventas` DISABLE KEYS */;
INSERT INTO `detalle_ventas` VALUES (1,1,4,4.00,28.00,0.00,112.00,NULL),(2,2,1,4.00,24.00,0.00,96.00,NULL),(3,2,2,4.00,26.00,0.00,104.00,NULL),(4,2,4,4.00,28.00,0.00,112.00,NULL),(5,3,1,3.00,24.00,0.00,72.00,NULL),(6,4,1,3.00,24.00,0.00,72.00,NULL);
/*!40000 ALTER TABLE `detalle_ventas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `historial_pedidos`
--

DROP TABLE IF EXISTS `historial_pedidos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `historial_pedidos` (
  `id_historial` int NOT NULL AUTO_INCREMENT,
  `id_pedido` int NOT NULL,
  `estado_antes` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `estado_despues` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `nota` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `realizado_por` int DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_historial`),
  KEY `fk_hist_pedido` (`id_pedido`),
  KEY `fk_hist_usuario` (`realizado_por`),
  KEY `idx_hist_pedido_fecha` (`id_pedido`,`creado_en`),
  CONSTRAINT `fk_hist_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`) ON DELETE CASCADE,
  CONSTRAINT `fk_hist_usuario` FOREIGN KEY (`realizado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=71 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Auditoría de cada cambio de estado en un pedido';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `historial_pedidos`
--

LOCK TABLES `historial_pedidos` WRITE;
/*!40000 ALTER TABLE `historial_pedidos` DISABLE KEYS */;
INSERT INTO `historial_pedidos` VALUES (46,12,'nuevo','pendiente','Pedido creado con 1 caja(s).',1,'2026-04-06 17:14:41'),(47,12,'pendiente','aprobado','Pedido aprobado.',1,'2026-04-06 17:14:50'),(48,12,'aprobado','en_produccion','Producción iniciada. Lote: L-0001',1,'2026-04-06 17:14:54'),(49,12,'en_produccion','listo','Producción terminada. Pedido listo para recoger.',1,'2026-04-06 17:14:58'),(50,12,'listo','entregado',NULL,1,'2026-04-06 17:15:09'),(51,13,'nuevo','pendiente','Pedido creado con 1 caja(s).',1,'2026-04-06 17:25:55'),(52,13,'pendiente','aprobado','Pedido aprobado.',1,'2026-04-06 17:26:05'),(53,13,'aprobado','en_produccion','Producción iniciada. Lote: L-0017',1,'2026-04-06 17:29:44'),(54,14,'nuevo','pendiente','Pedido creado con 1 caja(s).',3,'2026-04-06 20:28:42'),(55,14,'pendiente','aprobado','Pedido aprobado.',1,'2026-04-06 20:29:27'),(56,13,'en_produccion','listo','Producción terminada. Pedido listo para recoger.',1,'2026-04-06 23:36:34'),(57,14,'aprobado','en_produccion','Producción iniciada. Lote: L-0018',1,'2026-04-06 23:36:39'),(58,14,'en_produccion','listo','Producción terminada. Pedido listo para recoger.',1,'2026-04-06 23:36:44'),(59,15,'nuevo','pendiente','Pedido express creado por el cliente',3,'2026-04-12 15:20:00'),(60,16,'nuevo','pendiente','Pedido express. Pago: tarjeta',3,'2026-04-12 16:13:29'),(61,16,'pendiente','aprobado','Pedido aprobado.',1,'2026-04-12 16:13:42'),(63,15,'pendiente','aprobado','Pedido aprobado.',1,'2026-04-12 16:14:02'),(65,16,'aprobado','listo','Pedido listo para recoger.',1,'2026-04-12 16:18:02'),(66,13,'listo','entregado','Pedido entregado al cliente.',1,'2026-04-12 16:26:31'),(67,14,'listo','entregado','Pedido entregado al cliente.',1,'2026-04-12 20:11:01'),(68,16,'listo','entregado','Pedido entregado al cliente.',1,'2026-04-12 20:11:33'),(69,15,'aprobado','listo','Pedido listo para recoger.',1,'2026-04-12 20:30:39'),(70,15,'listo','entregado','Pedido entregado al cliente.',1,'2026-04-12 20:30:45');
/*!40000 ALTER TABLE `historial_pedidos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `insumos_lote_caja`
--

DROP TABLE IF EXISTS `insumos_lote_caja`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `insumos_lote_caja` (
  `id_insumo` int NOT NULL AUTO_INCREMENT,
  `id_lote` int NOT NULL,
  `id_receta` int NOT NULL,
  `id_materia` int NOT NULL,
  `cantidad_requerida` decimal(14,4) NOT NULL,
  `cantidad_descontada` decimal(14,4) NOT NULL,
  PRIMARY KEY (`id_insumo`),
  UNIQUE KEY `uq_insumo_lote_materia_receta` (`id_lote`,`id_materia`,`id_receta`),
  KEY `id_receta` (`id_receta`),
  KEY `id_materia` (`id_materia`),
  CONSTRAINT `insumos_lote_caja_ibfk_1` FOREIGN KEY (`id_lote`) REFERENCES `lotes_produccion_caja` (`id_lote`) ON DELETE CASCADE,
  CONSTRAINT `insumos_lote_caja_ibfk_2` FOREIGN KEY (`id_receta`) REFERENCES `recetas` (`id_receta`),
  CONSTRAINT `insumos_lote_caja_ibfk_3` FOREIGN KEY (`id_materia`) REFERENCES `materias_primas` (`id_materia`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `insumos_lote_caja`
--

LOCK TABLES `insumos_lote_caja` WRITE;
/*!40000 ALTER TABLE `insumos_lote_caja` DISABLE KEYS */;
/*!40000 ALTER TABLE `insumos_lote_caja` ENABLE KEYS */;
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
  KEY `idx_inv_stock_minimo` (`stock_actual`,`stock_minimo`),
  KEY `idx_inv_stock_estatus` (`id_producto`,`stock_actual`),
  CONSTRAINT `fk_inv_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Stock en tiempo real de cada producto terminado.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventario_pt`
--

LOCK TABLES `inventario_pt` WRITE;
/*!40000 ALTER TABLE `inventario_pt` DISABLE KEYS */;
INSERT INTO `inventario_pt` VALUES (1,1,74.00,20.00,'2026-04-12 16:14:02'),(2,2,0.00,20.00,'2026-03-24 14:42:13'),(3,3,0.00,20.00,'2026-03-24 14:42:13'),(4,4,0.00,15.00,'2026-03-24 14:42:13'),(5,5,72.00,20.00,'2026-04-09 09:25:50'),(6,6,0.00,15.00,'2026-03-24 14:42:13'),(7,7,72.00,15.00,'2026-04-09 09:23:07'),(8,8,0.00,15.00,'2026-03-24 14:42:13'),(9,9,0.00,20.00,'2026-03-24 14:42:13'),(10,10,0.00,20.00,'2026-03-24 14:42:13'),(11,11,0.00,15.00,'2026-03-24 14:42:13'),(12,12,40.00,25.00,'2026-04-09 12:42:31'),(13,14,0.00,0.00,'2026-03-31 15:48:33'),(20,15,0.00,0.00,'2026-04-09 13:47:03');
/*!40000 ALTER TABLE `inventario_pt` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `log_imagen_producto`
--

DROP TABLE IF EXISTS `log_imagen_producto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `log_imagen_producto` (
  `id_log` int NOT NULL AUTO_INCREMENT,
  `id_producto` int NOT NULL,
  `imagen_ant` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `imagen_nueva` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `accion` enum('subida','eliminada') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `cambiado_por` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cambiado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_log`),
  KEY `idx_log_prod` (`id_producto`),
  CONSTRAINT `fk_log_img_prod` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `log_imagen_producto`
--

LOCK TABLES `log_imagen_producto` WRITE;
/*!40000 ALTER TABLE `log_imagen_producto` DISABLE KEYS */;
INSERT INTO `log_imagen_producto` VALUES (1,15,NULL,'uploads/productos/d412c1ecc0fb4d259e0f12fc83d1c8f0.webp','subida',NULL,'2026-04-09 14:26:01'),(2,15,'uploads/productos/d412c1ecc0fb4d259e0f12fc83d1c8f0.webp','uploads/productos/fa697e5ab5e54be88086144ed2a2e4b4.webp','subida',NULL,'2026-04-09 14:26:04'),(3,15,'uploads/productos/fa697e5ab5e54be88086144ed2a2e4b4.webp','uploads/productos/3167f244de4644a393221807a07b9414.webp','subida',NULL,'2026-04-09 14:26:04'),(4,15,'uploads/productos/3167f244de4644a393221807a07b9414.webp','uploads/productos/fb4d49ebc3a24722b69c99cfd8321ca7.webp','subida',NULL,'2026-04-09 14:27:22'),(5,14,NULL,'uploads/productos/5499fe0a9cb341f48d20525abf6489f6.webp','subida',NULL,'2026-04-12 17:51:56'),(6,14,'uploads/productos/5499fe0a9cb341f48d20525abf6489f6.webp','uploads/productos/46b56e7c633a4e7698bef76537dd26d1.webp','subida',NULL,'2026-04-12 17:51:56'),(7,12,NULL,'uploads/productos/9922b75da93d4534abc6724212444452.webp','subida',NULL,'2026-04-12 17:51:57'),(8,12,'uploads/productos/9922b75da93d4534abc6724212444452.webp','uploads/productos/800d2d845b8a444e98fab88105750ead.webp','subida',NULL,'2026-04-12 17:52:43'),(9,12,'uploads/productos/800d2d845b8a444e98fab88105750ead.webp','uploads/productos/393c8b10fb094357ac54bf6694af7610.webp','subida',NULL,'2026-04-12 17:52:43'),(10,12,'uploads/productos/393c8b10fb094357ac54bf6694af7610.webp','uploads/productos/dc1cf9d76e0c42e0aecf8b29b63266ba.webp','subida',NULL,'2026-04-12 17:52:43'),(11,12,'uploads/productos/dc1cf9d76e0c42e0aecf8b29b63266ba.webp','uploads/productos/45dc80424cc142ba849b31c874059db0.webp','subida',NULL,'2026-04-12 17:52:45'),(12,14,'uploads/productos/46b56e7c633a4e7698bef76537dd26d1.webp',NULL,'eliminada',NULL,'2026-04-12 17:53:57'),(13,14,NULL,'uploads/productos/2a25755f409343a3a4e3aec5e98a0663.webp','subida',NULL,'2026-04-12 18:15:28'),(14,2,NULL,'uploads/productos/d109c463a12f46759021166714b1c553.webp','subida',NULL,'2026-04-12 18:19:09'),(15,2,'uploads/productos/d109c463a12f46759021166714b1c553.webp','uploads/productos/bae2af7569c5438787e9d2b85af48462.webp','subida',NULL,'2026-04-12 18:19:29'),(16,1,NULL,'uploads/productos/6910200044964811b2115dd630b96598.webp','subida',NULL,'2026-04-12 18:24:05'),(17,3,NULL,'uploads/productos/9f26775a346441a695892bd59fde5bb5.webp','subida',NULL,'2026-04-12 18:26:36'),(18,11,NULL,'uploads/productos/9c7c9b600a6a4f269bb0084c74170f37.webp','subida',NULL,'2026-04-12 18:27:23'),(19,11,'uploads/productos/9c7c9b600a6a4f269bb0084c74170f37.webp','uploads/productos/8aae76edad1d4975ad59079dd19f11f4.webp','subida',NULL,'2026-04-12 18:27:24'),(20,5,NULL,'uploads/productos/0d81b351cfb24e419f3470f9fde6497b.webp','subida',NULL,'2026-04-12 18:29:54'),(21,4,NULL,'uploads/productos/34a23ece834748c09595291f5afb82db.webp','subida',NULL,'2026-04-12 18:33:36'),(22,10,NULL,'uploads/productos/ccfe66de7fa04b5fad626ac03701a853.webp','subida',NULL,'2026-04-12 18:34:32'),(23,9,NULL,'uploads/productos/b55469d046f74c618718faee06ffbd59.webp','subida',NULL,'2026-04-12 18:34:47'),(24,6,NULL,'uploads/productos/9cd95bd9da0a4657a7913c6ac1ef16ed.webp','subida',NULL,'2026-04-12 18:37:56'),(25,7,NULL,'uploads/productos/744e67025b564d7e8d44cb8e359b2c23.webp','subida',NULL,'2026-04-12 18:38:56'),(26,8,NULL,'uploads/productos/3668cd2d826346db9b1cf726c47437c6.webp','subida',NULL,'2026-04-12 18:39:32'),(27,14,'uploads/productos/2a25755f409343a3a4e3aec5e98a0663.webp','uploads/productos/a863abdeae4e45bbb9821231abd5f8b7.webp','subida',NULL,'2026-04-12 19:21:01');
/*!40000 ALTER TABLE `log_imagen_producto` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `logs_sistema`
--

DROP TABLE IF EXISTS `logs_sistema`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `logs_sistema` (
  `id_log` bigint NOT NULL AUTO_INCREMENT,
  `tipo` enum('error','acceso','cambio_usuario','venta','compra','produccion','ajuste_inv','solicitud','salida_efectivo','seguridad','pedido') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `logs_sistema`
--

LOCK TABLES `logs_sistema` WRITE;
/*!40000 ALTER TABLE `logs_sistema` DISABLE KEYS */;
INSERT INTO `logs_sistema` VALUES (1,'produccion','INFO',2,'Pedidos','iniciar_produccion','Pedido PED-0004 → en_produccion. Lote: L-0006',NULL,NULL,4,'pedidos','2026-04-01 17:23:32'),(2,'produccion','INFO',1,'Pedidos','iniciar_produccion','Pedido PED-0002 → en_produccion. Lote: L-0007',NULL,NULL,2,'pedidos','2026-04-01 19:08:00'),(3,'produccion','INFO',1,'Pedidos','terminar_produccion','Pedido PED-0002 terminado → listo. Cliente notificado.',NULL,NULL,2,'pedidos','2026-04-01 19:11:31'),(4,'produccion','INFO',1,'Pedidos','terminar_produccion','Pedido PED-0004 terminado → listo. Cliente notificado.',NULL,NULL,4,'pedidos','2026-04-04 16:39:02'),(5,'compra','INFO',NULL,'proveedores','TOGGLE_ESTATUS','Proveedor \"Huevo Y Materias Primas Para Pan, Sa De Cv\" cambiado a inactivo',NULL,NULL,NULL,NULL,'2026-04-05 15:23:41'),(6,'compra','INFO',NULL,'proveedores','TOGGLE_ESTATUS','Proveedor \"Huevo Y Materias Primas Para Pan, Sa De Cv\" cambiado a activo',NULL,NULL,NULL,NULL,'2026-04-05 15:23:52'),(7,'compra','INFO',NULL,'proveedores','TOGGLE_ESTATUS','Proveedor \"Huevo Y Materias Primas Para Pan, Sa De Cv\" cambiado a inactivo',NULL,NULL,NULL,NULL,'2026-04-05 15:24:02'),(8,'compra','INFO',NULL,'proveedores','TOGGLE_ESTATUS','Proveedor \"Huevo Y Materias Primas Para Pan, Sa De Cv\" cambiado a activo',NULL,NULL,NULL,NULL,'2026-04-05 15:24:10'),(9,'produccion','INFO',1,'Pedidos','iniciar_produccion','Pedido PED-0003 → en_produccion. Lote: L-0008',NULL,NULL,3,'pedidos','2026-04-05 15:48:36'),(10,'produccion','INFO',1,'Pedidos','terminar_produccion','Pedido PED-0003 terminado → listo. Cliente notificado.',NULL,NULL,3,'pedidos','2026-04-05 15:49:39'),(11,'produccion','INFO',1,'Pedidos','iniciar_produccion','Pedido PED-0005 → en_produccion. Lote: L-0009',NULL,NULL,5,'pedidos','2026-04-05 15:50:26'),(12,'produccion','INFO',1,'Pedidos','iniciar_produccion','Pedido PED-0010 → en_produccion. Lote: L-0010',NULL,NULL,10,'pedidos','2026-04-05 15:50:50'),(13,'produccion','INFO',1,'Pedidos','terminar_produccion','Pedido PED-0005 terminado → listo. Cliente notificado.',NULL,NULL,5,'pedidos','2026-04-05 15:51:01'),(14,'produccion','INFO',1,'Pedidos','terminar_produccion','Pedido PED-0010 terminado → listo. Cliente notificado.',NULL,NULL,10,'pedidos','2026-04-05 16:00:44'),(15,'produccion','INFO',1,'Pedidos','iniciar_produccion','Pedido PED-0007 → en_produccion. Lote: L-0011',NULL,NULL,7,'pedidos','2026-04-05 16:15:03'),(16,'produccion','INFO',1,'Pedidos','terminar_produccion','Pedido PED-0007 terminado → listo. Cliente notificado.',NULL,NULL,7,'pedidos','2026-04-05 16:15:38'),(17,'produccion','INFO',1,'Pedidos','iniciar_produccion','Pedido PED-0001 → en_produccion. Lote: L-0012',NULL,NULL,1,'pedidos','2026-04-05 16:23:05'),(18,'produccion','INFO',1,'Pedidos','iniciar_produccion','Pedido PED-0006 → en_produccion. Lote: L-0013',NULL,NULL,6,'pedidos','2026-04-05 17:06:11'),(19,'produccion','INFO',1,'Pedidos','iniciar_produccion','Pedido PED-0011 → en_produccion. Lote: L-0014',NULL,NULL,11,'pedidos','2026-04-05 17:29:16'),(20,'produccion','INFO',1,'Pedidos','iniciar_produccion','Pedido PED-0006 → en_produccion. Lote: L-0015',NULL,NULL,6,'pedidos','2026-04-05 18:13:38'),(21,'produccion','INFO',1,'Pedidos','iniciar_produccion','Pedido PED-0001 → en_produccion. Lote: L-0001',NULL,NULL,12,'pedidos','2026-04-06 17:14:54'),(22,'produccion','INFO',1,'Pedidos','terminar_produccion','Pedido PED-0001 terminado → listo. Cliente notificado.',NULL,NULL,12,'pedidos','2026-04-06 17:14:58'),(23,'produccion','INFO',1,'Pedidos','iniciar_produccion','Pedido PED-0013 → en_produccion. Lote: L-0017',NULL,NULL,13,'pedidos','2026-04-06 17:29:44'),(24,'compra','INFO',NULL,'proveedores','CREAR','Proveedor creado: Industriamart',NULL,NULL,NULL,NULL,'2026-04-06 17:44:55'),(25,'compra','INFO',NULL,'proveedores','EDITAR','Proveedor editado: Industriamart (id=2)',NULL,NULL,NULL,NULL,'2026-04-06 17:45:13'),(26,'produccion','INFO',1,'Pedidos','terminar_produccion','Pedido PED-0013 terminado → listo. Cliente notificado.',NULL,NULL,13,'pedidos','2026-04-06 23:36:34'),(27,'produccion','INFO',1,'Pedidos','iniciar_produccion','Pedido PED-0014 → en_produccion. Lote: L-0018',NULL,NULL,14,'pedidos','2026-04-06 23:36:39'),(28,'produccion','INFO',1,'Pedidos','terminar_produccion','Pedido PED-0014 terminado → listo. Cliente notificado.',NULL,NULL,14,'pedidos','2026-04-06 23:36:44'),(29,'produccion','INFO',1,'ProduccionDiaria','estado_en_proceso','Producción PD-0001 cambió de \"pendiente\" a \"en_proceso\"',NULL,NULL,1,'produccion_diaria','2026-04-08 10:04:48'),(30,'produccion','INFO',1,'ProduccionDiaria','estado_finalizado','Producción PD-0001 cambió de \"en_proceso\" a \"finalizado\"',NULL,NULL,1,'produccion_diaria','2026-04-08 10:05:16'),(31,'produccion','INFO',1,'ProduccionDiaria','estado_en_proceso','Producción PD-0002 cambió de \"pendiente\" a \"en_proceso\"',NULL,NULL,2,'produccion_diaria','2026-04-08 17:21:06'),(32,'produccion','INFO',1,'ProduccionDiaria','estado_finalizado','Producción PD-0002 cambió de \"en_proceso\" a \"finalizado\"',NULL,NULL,2,'produccion_diaria','2026-04-08 17:22:35'),(33,'produccion','INFO',1,'ProduccionDiaria','estado_en_proceso','Producción PD-0003 cambió de \"pendiente\" a \"en_proceso\"',NULL,NULL,3,'produccion_diaria','2026-04-09 09:22:51'),(34,'produccion','INFO',1,'ProduccionDiaria','estado_finalizado','Producción PD-0003 cambió de \"en_proceso\" a \"finalizado\"',NULL,NULL,3,'produccion_diaria','2026-04-09 09:23:07'),(35,'produccion','INFO',1,'ProduccionDiaria','estado_en_proceso','Producción PD-0004 cambió de \"pendiente\" a \"en_proceso\"',NULL,NULL,4,'produccion_diaria','2026-04-09 09:23:57'),(36,'produccion','INFO',1,'ProduccionDiaria','estado_finalizado','Producción PD-0004 cambió de \"en_proceso\" a \"finalizado\"',NULL,NULL,4,'produccion_diaria','2026-04-09 09:25:50'),(37,'produccion','INFO',1,'ProduccionDiaria','estado_en_proceso','Producción PD-0001 cambió de \"pendiente\" a \"en_proceso\"',NULL,NULL,1,'produccion_diaria','2026-04-09 11:41:56'),(38,'produccion','INFO',1,'ProduccionDiaria','estado_finalizado','Producción PD-0001 cambió de \"en_proceso\" a \"finalizado\"',NULL,NULL,1,'produccion_diaria','2026-04-09 11:42:08'),(39,'produccion','INFO',1,'ProduccionDiaria','estado_en_proceso','Producción PD-0002 cambió de \"pendiente\" a \"en_proceso\"',NULL,NULL,2,'produccion_diaria','2026-04-09 12:41:54'),(40,'produccion','INFO',1,'ProduccionDiaria','estado_finalizado','Producción PD-0002 cambió de \"en_proceso\" a \"finalizado\"',NULL,NULL,2,'produccion_diaria','2026-04-09 12:42:31'),(41,'pedido','INFO',1,'Pedidos','marcar_listo','Pedido PED-0016 marcado como listo.',NULL,NULL,16,'pedidos','2026-04-12 16:18:02'),(42,'venta','INFO',1,'ventas','venta_automatica','Venta automática desde pedido PED-0013 | Folio venta: VTA-20260412-001',NULL,NULL,13,'pedido','2026-04-12 16:26:31'),(43,'venta','INFO',1,'ventas','venta_automatica','Venta automática desde pedido PED-0014 | Folio venta: VTA-20260412-002',NULL,NULL,14,'pedido','2026-04-12 20:11:01'),(44,'venta','INFO',1,'ventas','venta_automatica','Venta automática desde pedido PED-0016 | Folio venta: VTA-20260412-003',NULL,NULL,16,'pedido','2026-04-12 20:11:33'),(45,'pedido','INFO',1,'Pedidos','marcar_listo','Pedido PED-0015 marcado como listo.',NULL,NULL,15,'pedidos','2026-04-12 20:30:39'),(46,'venta','INFO',1,'ventas','venta_automatica','Venta automática desde pedido PED-0015 | Folio venta: VTA-20260412-004',NULL,NULL,15,'pedido','2026-04-12 20:30:45'),(47,'venta','INFO',NULL,'productos','EDITAR','Producto editado: Bagget Relleno (id=14)',NULL,NULL,NULL,NULL,'2026-04-14 11:31:51'),(48,'venta','INFO',NULL,'productos','TOGGLE_ESTATUS','Producto \"Bagget Relleno\" cambiado a inactivo',NULL,NULL,NULL,NULL,'2026-04-14 11:32:59'),(49,'venta','INFO',NULL,'productos','TOGGLE_ESTATUS','Producto \"Bagget Relleno\" cambiado a activo',NULL,NULL,NULL,NULL,'2026-04-14 11:33:05'),(50,'compra','INFO',NULL,'proveedores','EDITAR','Proveedor editado: Huevo Y Materias Primas Para Pan, Sa De Cv (id=1)',NULL,NULL,NULL,NULL,'2026-04-14 21:29:37');
/*!40000 ALTER TABLE `logs_sistema` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `lotes_produccion_caja`
--

DROP TABLE IF EXISTS `lotes_produccion_caja`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `lotes_produccion_caja` (
  `id_lote` int NOT NULL AUTO_INCREMENT,
  `folio_lote` varchar(30) NOT NULL,
  `id_caja` int NOT NULL,
  `cantidad_cajas` int NOT NULL,
  `piezas_esperadas` int NOT NULL,
  `estado` enum('pendiente','en_proceso','finalizado','cancelado') NOT NULL,
  `insumos_descontados` tinyint(1) NOT NULL,
  `inventario_acreditado` tinyint(1) NOT NULL,
  `fecha_inicio` datetime DEFAULT NULL,
  `fecha_fin_real` datetime DEFAULT NULL,
  `operario_id` int DEFAULT NULL,
  `observaciones` text,
  `creado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_lote`),
  UNIQUE KEY `folio_lote` (`folio_lote`),
  KEY `operario_id` (`operario_id`),
  KEY `creado_por` (`creado_por`),
  CONSTRAINT `lotes_produccion_caja_ibfk_1` FOREIGN KEY (`operario_id`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `lotes_produccion_caja_ibfk_2` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `lotes_produccion_caja`
--

LOCK TABLES `lotes_produccion_caja` WRITE;
/*!40000 ALTER TABLE `lotes_produccion_caja` DISABLE KEYS */;
/*!40000 ALTER TABLE `lotes_produccion_caja` ENABLE KEYS */;
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
  `stock_actual` decimal(10,2) DEFAULT NULL,
  `stock_minimo` decimal(10,2) DEFAULT NULL,
  `estatus` enum('activo','inactivo') NOT NULL,
  `creado_en` datetime NOT NULL,
  `actualizado_en` datetime NOT NULL,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_materia`),
  UNIQUE KEY `uuid_materia` (`uuid_materia`),
  KEY `creado_por` (`creado_por`),
  KEY `idx_mp_nombre` (`nombre`),
  KEY `idx_mp_estatus` (`estatus`),
  KEY `idx_mp_categoria` (`categoria`),
  KEY `idx_mp_stock_critico` (`estatus`,`stock_actual`,`stock_minimo`),
  CONSTRAINT `materias_primas_ibfk_1` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `materias_primas`
--

LOCK TABLES `materias_primas` WRITE;
/*!40000 ALTER TABLE `materias_primas` DISABLE KEYS */;
INSERT INTO `materias_primas` VALUES (1,'84bb422b-2613-11f1-9474-c01850d072b8','Harina de Trigo','Harinas','g',31043.00,5000.00,'activo','2026-03-22 11:21:09','2026-04-09 12:41:54',1),(2,'84bd05a6-2613-11f1-9474-c01850d072b8','Azúcar Refinada','Endulzantes','g',9486.34,2000.00,'activo','2026-03-22 11:21:09','2026-04-09 12:41:54',1),(3,'84bd0bd2-2613-11f1-9474-c01850d072b8','Mantequilla','Grasas','g',3488.37,2000.00,'activo','2026-03-22 11:21:09','2026-04-09 12:41:54',1),(4,'84bd0f0a-2613-11f1-9474-c01850d072b8','Leche Entera','Lácteos','ml',6833.52,1000.00,'activo','2026-03-22 11:21:09','2026-04-09 12:41:54',1),(5,'84bd1c40-2613-11f1-9474-c01850d072b8','Levadura Seca','Fermentación','g',2197.71,100.00,'activo','2026-03-22 11:21:09','2026-04-09 12:41:54',1),(6,'84bd1fe6-2613-11f1-9474-c01850d072b8','Huevo','Proteínas','pza',47.00,45.00,'activo','2026-03-22 11:21:09','2026-04-09 12:41:54',1),(7,'84bd2126-2613-11f1-9474-c01850d072b8','Sal','Condimentos','g',1792.31,200.00,'activo','2026-03-22 11:21:09','2026-04-09 12:41:54',1),(8,'84bd22ba-2613-11f1-9474-c01850d072b8','Esencia de Vainilla','Saborizantes','ml',2212.74,50.00,'activo','2026-03-22 11:21:09','2026-04-09 12:41:54',1),(9,'84bd23ed-2613-11f1-9474-c01850d072b8','Cocoa en Polvo','Saborizantes','g',2244.16,300.00,'activo','2026-03-22 11:21:09','2026-04-06 23:36:39',1),(10,'84bd24f6-2613-11f1-9474-c01850d072b8','Canela Molida','Especias','g',910.00,100.00,'activo','2026-03-22 11:21:09','2026-04-09 09:22:51',1),(11,'84bd2613-2613-11f1-9474-c01850d072b8','Queso Crema','Lácteos','g',2235.00,500.00,'activo','2026-03-22 11:21:09','2026-04-05 18:13:38',1),(12,'84bd5a67-2613-11f1-9474-c01850d072b8','Cajeta','Rellenos','g',1740.00,300.00,'activo','2026-03-22 11:21:09','2026-04-05 18:13:38',1),(13,'84bd64c5-2613-11f1-9474-c01850d072b8','Crema Pastelera','Rellenos','g',4146.66,500.00,'activo','2026-03-22 11:21:09','2026-04-09 12:41:54',1),(14,'84bd6626-2613-11f1-9474-c01850d072b8','Mermelada de Fresa','Rellenos','g',3720.00,400.00,'activo','2026-03-22 11:21:09','2026-04-06 17:14:54',1),(15,'84bd6799-2613-11f1-9474-c01850d072b8','Crema de Avellana','Rellenos','g',2304.17,300.00,'activo','2026-03-22 11:21:09','2026-04-06 23:36:39',1),(16,'84bd694b-2613-11f1-9474-c01850d072b8','Dulce de Leche','Rellenos','g',1018.00,300.00,'activo','2026-03-22 11:21:09','2026-04-09 09:23:57',1),(17,'84bd6a5b-2613-11f1-9474-c01850d072b8','Crema de Limón','Rellenos','g',956.67,200.00,'activo','2026-03-22 11:21:09','2026-04-05 18:13:38',1),(18,'84bd6b7d-2613-11f1-9474-c01850d072b8','Piloncillo','Endulzantes','g',4800.00,400.00,'activo','2026-03-22 11:21:09','2026-04-09 09:22:51',1),(19,'84bd6c9b-2613-11f1-9474-c01850d072b8','Requesón','Lácteos','g',3200.00,300.00,'activo','2026-03-22 11:21:09','2026-03-22 11:21:09',1),(20,'84bd6dbd-2613-11f1-9474-c01850d072b8','Azúcar Glass','Endulzantes','g',10627.33,300.00,'activo','2026-03-22 11:21:09','2026-04-09 12:41:54',1),(21,'474e27bc-2959-11f1-828b-c01850d072b8','Caja de Cartón Chica','Empaque','pza',77.00,10.00,'activo','2026-03-26 15:18:05','2026-04-09 12:41:54',1),(22,'4751491a-2959-11f1-828b-c01850d072b8','Caja de Cartón Mediana','Empaque','pza',74.00,10.00,'activo','2026-03-26 15:18:05','2026-04-09 09:23:57',1),(23,'47514b46-2959-11f1-828b-c01850d072b8','Caja de Cartón Grande','Empaque','pza',66.00,10.00,'activo','2026-03-26 15:18:05','2026-04-09 09:22:51',1),(24,'7bf94a5d-2f38-4721-91dc-f454a69ec7ac','Queso rallado','Lácteos y grasas','g',2500.00,2000.00,'activo','2026-04-06 20:12:25','2026-04-06 20:12:25',NULL);
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
-- Table structure for table `notificaciones_pedidos`
--

DROP TABLE IF EXISTS `notificaciones_pedidos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notificaciones_pedidos` (
  `id_notif` int NOT NULL AUTO_INCREMENT,
  `id_pedido` int NOT NULL,
  `id_usuario` int NOT NULL COMMENT 'Destinatario',
  `folio` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tipo` enum('aprobado','rechazado','listo','entregado') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `mensaje` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `leida` tinyint(1) NOT NULL DEFAULT '0',
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_notif`),
  KEY `fk_notif_pedido` (`id_pedido`),
  KEY `fk_notif_usuario` (`id_usuario`),
  KEY `idx_notif_usuario_leida` (`id_usuario`,`leida`),
  KEY `idx_notif_folio` (`folio`),
  CONSTRAINT `fk_notif_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`) ON DELETE CASCADE,
  CONSTRAINT `fk_notif_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=38 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Notificaciones de estado al cliente';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notificaciones_pedidos`
--

LOCK TABLES `notificaciones_pedidos` WRITE;
/*!40000 ALTER TABLE `notificaciones_pedidos` DISABLE KEYS */;
INSERT INTO `notificaciones_pedidos` VALUES (21,12,1,'PED-0001','aprobado','Tu pedido PED-0001 ha sido aprobado. Pronto comenzará su producción.',1,'2026-04-06 17:14:50'),(22,12,1,'PED-0001','listo','? ¡Tu pedido PED-0001 está listo! Pasa a recogerlo cuando quieras.',1,'2026-04-06 17:14:58'),(23,12,1,'PED-0001','entregado','Tu pedido PED-0001 ahora está: entregado',1,'2026-04-06 17:15:09'),(24,13,1,'PED-0013','aprobado','Tu pedido PED-0013 ha sido aprobado. Pronto comenzará su producción.',1,'2026-04-06 17:26:05'),(25,14,3,'PED-0014','aprobado','Tu pedido PED-0014 ha sido aprobado. Pronto comenzará su producción.',1,'2026-04-06 20:29:27'),(26,13,1,'PED-0013','listo','? ¡Tu pedido PED-0013 está listo! Pasa a recogerlo cuando quieras.',1,'2026-04-06 23:36:34'),(27,14,3,'PED-0014','listo','? ¡Tu pedido PED-0014 está listo! Pasa a recogerlo cuando quieras.',1,'2026-04-06 23:36:44'),(28,16,3,'PED-0016','aprobado','✅ Tu pedido PED-0016 fue aprobado y está siendo preparado.',1,'2026-04-12 16:13:42'),(30,15,3,'PED-0015','aprobado','✅ Tu pedido PED-0015 fue aprobado y está siendo preparado.',1,'2026-04-12 16:14:02'),(32,16,3,'PED-0016','listo','? ¡Tu pedido PED-0016 está listo! Pasa a recogerlo.',1,'2026-04-12 16:18:02'),(33,13,1,'PED-0013','entregado','? Tu pedido PED-0013 ha sido entregado. ¡Gracias!',0,'2026-04-12 16:26:31'),(34,14,3,'PED-0014','entregado','? Tu pedido PED-0014 ha sido entregado. ¡Gracias!',1,'2026-04-12 20:11:01'),(35,16,3,'PED-0016','entregado','? Tu pedido PED-0016 ha sido entregado. ¡Gracias!',1,'2026-04-12 20:11:33'),(36,15,3,'PED-0015','listo','? ¡Tu pedido PED-0015 está listo! Pasa a recogerlo.',1,'2026-04-12 20:30:39'),(37,15,3,'PED-0015','entregado','? Tu pedido PED-0015 ha sido entregado. ¡Gracias!',1,'2026-04-12 20:30:45');
/*!40000 ALTER TABLE `notificaciones_pedidos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pedido_productos`
--

DROP TABLE IF EXISTS `pedido_productos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pedido_productos` (
  `id_pedido_producto` int NOT NULL AUTO_INCREMENT,
  `id_pedido` int NOT NULL,
  `id_producto` int NOT NULL,
  `cantidad` tinyint NOT NULL,
  `precio_unitario` decimal(10,2) NOT NULL,
  PRIMARY KEY (`id_pedido_producto`),
  KEY `fk_pp_pedido` (`id_pedido`),
  KEY `fk_pp_producto` (`id_producto`),
  CONSTRAINT `fk_pp_pedido` FOREIGN KEY (`id_pedido`) REFERENCES `pedidos` (`id_pedido`) ON DELETE CASCADE,
  CONSTRAINT `fk_pp_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Panes individuales que componen cada pedido de caja.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pedido_productos`
--

LOCK TABLES `pedido_productos` WRITE;
/*!40000 ALTER TABLE `pedido_productos` DISABLE KEYS */;
/*!40000 ALTER TABLE `pedido_productos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pedidos`
--

DROP TABLE IF EXISTS `pedidos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pedidos` (
  `id_pedido` int NOT NULL AUTO_INCREMENT,
  `uuid_pedido` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `folio` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'PED-0001',
  `id_cliente` int NOT NULL COMMENT 'FK a usuarios con rol cliente',
  `id_tamanio` int DEFAULT NULL COMMENT 'FK a tamanios_charola',
  `tipo` enum('simple','mixta','triple') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'simple' COMMENT 'Tipo de caja pedida',
  `estado` enum('pendiente','aprobado','listo','entregado','rechazado') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'pendiente',
  `fecha_recogida` datetime NOT NULL COMMENT 'Cuándo quiere recoger el cliente',
  `notas_cliente` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Indicaciones especiales del cliente',
  `metodo_pago` enum('efectivo','tarjeta','transferencia') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'efectivo',
  `motivo_rechazo` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'Razón del rechazo, visible al cliente',
  `total_estimado` decimal(10,2) NOT NULL DEFAULT '0.00',
  `atendido_por` int DEFAULT NULL COMMENT 'Usuario que aprobó/rechazó',
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_pedido`),
  UNIQUE KEY `uq_uuid_pedido` (`uuid_pedido`),
  UNIQUE KEY `uq_folio_pedido` (`folio`),
  KEY `fk_pedido_atiende` (`atendido_por`),
  KEY `idx_pedidos_estado` (`estado`),
  KEY `idx_pedidos_estado_fecha` (`estado`,`fecha_recogida`),
  KEY `idx_pedidos_cliente_estado` (`id_cliente`,`estado`),
  KEY `idx_pedidos_tamanio` (`id_tamanio`),
  KEY `idx_pedidos_folio` (`folio`),
  KEY `idx_pedidos_fecha_recogida` (`fecha_recogida`),
  KEY `idx_pedidos_metodo_pago` (`metodo_pago`),
  KEY `idx_pedidos_estado_actualizado` (`estado`,`actualizado_en`),
  CONSTRAINT `fk_pedido_atiende` FOREIGN KEY (`atendido_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `fk_pedido_cliente` FOREIGN KEY (`id_cliente`) REFERENCES `usuarios` (`id_usuario`) ON DELETE RESTRICT,
  CONSTRAINT `fk_pedido_tamanio` FOREIGN KEY (`id_tamanio`) REFERENCES `tamanios_charola` (`id_tamanio`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Cabecera de pedidos realizados por clientes web';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pedidos`
--

LOCK TABLES `pedidos` WRITE;
/*!40000 ALTER TABLE `pedidos` DISABLE KEYS */;
INSERT INTO `pedidos` VALUES (12,'64186dea-320e-11f1-b06d-c01850d072b8','PED-0001',1,NULL,'mixta','entregado','2026-04-05 18:15:00',NULL,'efectivo',NULL,252.00,1,'2026-04-06 17:14:41','2026-04-06 18:28:32'),(13,'f601976f-320f-11f1-b06d-c01850d072b8','PED-0013',1,NULL,'mixta','entregado','2026-04-06 18:30:00',NULL,'efectivo',NULL,112.00,1,'2026-04-06 17:25:55','2026-04-12 16:26:31'),(14,'7ec6ee4d-3229-11f1-b06d-c01850d072b8','PED-0014',3,NULL,'mixta','entregado','2026-04-07 09:15:00',NULL,'efectivo',NULL,312.00,1,'2026-04-06 20:28:42','2026-04-12 20:11:01'),(15,'5d40039e-36b5-11f1-b06d-c01850d072b8','PED-0015',3,NULL,'simple','entregado','2026-04-12 18:15:00',NULL,'efectivo',NULL,72.00,1,'2026-04-12 15:20:00','2026-04-12 20:30:45'),(16,'d5e9dabb-36bc-11f1-b06d-c01850d072b8','PED-0016',3,NULL,'simple','entregado','2026-04-12 16:30:00',NULL,'tarjeta',NULL,72.00,1,'2026-04-12 16:13:29','2026-04-12 20:11:33');
/*!40000 ALTER TABLE `pedidos` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`dm_restore`@`localhost`*/ /*!50003 TRIGGER `trg_pedido_metodo_pago_auditoria` AFTER UPDATE ON `pedidos` FOR EACH ROW BEGIN
  IF OLD.metodo_pago <> NEW.metodo_pago THEN
    INSERT INTO logs_sistema
      (tipo, nivel, id_usuario, modulo, accion, descripcion,
       referencia_id, referencia_tipo, creado_en)
    VALUES
      ('pedido', 'INFO', NEW.atendido_por, 'Pedidos', 'cambio_metodo_pago',
       CONCAT('Pedido ', NEW.folio, ': método de pago cambió de ',
              OLD.metodo_pago, ' a ', NEW.metodo_pago),
       NEW.id_pedido, 'pedidos', NOW());
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_pedido_entregado_venta` AFTER UPDATE ON `pedidos` FOR EACH ROW BEGIN
    DECLARE v_id_venta INT;
    
    -- Cuando el estado cambia a 'entregado'
    IF NEW.estado = 'entregado' AND OLD.estado != 'entregado' THEN
        -- Verificar que no exista ya una venta para este pedido
        IF NOT EXISTS (SELECT 1 FROM logs_sistema 
                       WHERE referencia_id = NEW.id_pedido 
                         AND referencia_tipo = 'pedido' 
                         AND accion = 'venta_automatica') THEN
            
            -- Crear la venta automática
            CALL sp_crear_venta_desde_pedido(NEW.id_pedido, NEW.atendido_por, @v_id_venta);
            
            -- Registrar que este pedido generó una venta
            INSERT INTO logs_sistema (tipo, nivel, modulo, accion, descripcion, 
                                      referencia_id, referencia_tipo, creado_en)
            VALUES ('venta', 'INFO', 'pedidos', 'venta_automatica', 
                    CONCAT('Pedido ', NEW.folio, ' convertido a venta automáticamente'),
                    NEW.id_pedido, 'pedido', NOW());
            
            -- También registrar la relación inversa (para excluir de la vista)
            INSERT INTO logs_sistema (tipo, nivel, modulo, accion, descripcion,
                                      referencia_id, referencia_tipo, creado_en)
            VALUES ('venta', 'INFO', 'ventas', 'venta_automatica',
                    CONCAT('Venta generada desde pedido ', NEW.folio),
                    @v_id_venta, 'venta', NOW());
        END IF;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `plantillas_produccion`
--

DROP TABLE IF EXISTS `plantillas_produccion`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `plantillas_produccion` (
  `id_plantilla` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(120) NOT NULL,
  `descripcion` text,
  `creado_por` int DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_plantilla`),
  KEY `idx_plant_usr` (`creado_por`),
  CONSTRAINT `fk_plant_usr` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Plantillas reutilizables de producción diaria';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `plantillas_produccion`
--

LOCK TABLES `plantillas_produccion` WRITE;
/*!40000 ALTER TABLE `plantillas_produccion` DISABLE KEYS */;
/*!40000 ALTER TABLE `plantillas_produccion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `plantillas_produccion_detalle`
--

DROP TABLE IF EXISTS `plantillas_produccion_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `plantillas_produccion_detalle` (
  `id_ppd` int NOT NULL AUTO_INCREMENT,
  `id_plantilla` int NOT NULL,
  `id_producto` int NOT NULL,
  `id_receta` int NOT NULL,
  `cantidad_piezas` int NOT NULL,
  PRIMARY KEY (`id_ppd`),
  KEY `idx_ppd_plant` (`id_plantilla`),
  KEY `fk_ppd_prod` (`id_producto`),
  KEY `fk_ppd_rec` (`id_receta`),
  CONSTRAINT `fk_ppd_plant` FOREIGN KEY (`id_plantilla`) REFERENCES `plantillas_produccion` (`id_plantilla`) ON DELETE CASCADE,
  CONSTRAINT `fk_ppd_prod` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`),
  CONSTRAINT `fk_ppd_rec` FOREIGN KEY (`id_receta`) REFERENCES `recetas` (`id_receta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `plantillas_produccion_detalle`
--

LOCK TABLES `plantillas_produccion_detalle` WRITE;
/*!40000 ALTER TABLE `plantillas_produccion_detalle` DISABLE KEYS */;
/*!40000 ALTER TABLE `plantillas_produccion_detalle` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `plantillas_produccion_linea_prod`
--

DROP TABLE IF EXISTS `plantillas_produccion_linea_prod`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `plantillas_produccion_linea_prod` (
  `id_pplp` int NOT NULL AUTO_INCREMENT,
  `id_ppd` int NOT NULL,
  `id_producto` int NOT NULL,
  `id_receta` int NOT NULL,
  `piezas_por_caja` tinyint NOT NULL,
  PRIMARY KEY (`id_pplp`),
  KEY `idx_pplp_ppd` (`id_ppd`),
  KEY `fk_pplp_prod` (`id_producto`),
  KEY `fk_pplp_rec` (`id_receta`),
  CONSTRAINT `fk_pplp_ppd` FOREIGN KEY (`id_ppd`) REFERENCES `plantillas_produccion_detalle` (`id_ppd`) ON DELETE CASCADE,
  CONSTRAINT `fk_pplp_prod` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`),
  CONSTRAINT `fk_pplp_rec` FOREIGN KEY (`id_receta`) REFERENCES `recetas` (`id_receta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `plantillas_produccion_linea_prod`
--

LOCK TABLES `plantillas_produccion_linea_prod` WRITE;
/*!40000 ALTER TABLE `plantillas_produccion_linea_prod` DISABLE KEYS */;
/*!40000 ALTER TABLE `plantillas_produccion_linea_prod` ENABLE KEYS */;
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
  KEY `idx_prod_estado` (`estado`),
  KEY `idx_prod_estado_fecha` (`estado`,`creado_en`),
  KEY `idx_prod_creado_en` (`creado_en`),
  CONSTRAINT `fk_produccion_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`),
  CONSTRAINT `produccion_ibfk_1` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `produccion_ibfk_3` FOREIGN KEY (`id_receta`) REFERENCES `recetas` (`id_receta`),
  CONSTRAINT `produccion_ibfk_4` FOREIGN KEY (`operario_id`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `produccion`
--

LOCK TABLES `produccion` WRITE;
/*!40000 ALTER TABLE `produccion` DISABLE KEYS */;
INSERT INTO `produccion` VALUES (16,'L-0001',12,64,1.00,6.00,6.00,'finalizado','2026-04-06 17:14:54',NULL,'2026-04-06 17:14:58',1,'Pedido PED-0001','2026-04-06 17:14:54',1),(17,'L-0017',4,56,0.67,4.00,4.00,'finalizado','2026-04-06 17:29:44',NULL,'2026-04-06 23:36:34',1,'Pedido PED-0013','2026-04-06 17:29:44',1),(18,'L-0018',1,53,0.67,4.00,4.00,'finalizado','2026-04-06 23:36:39',NULL,'2026-04-06 23:36:44',1,'Pedido PED-0014','2026-04-06 23:36:39',1);
/*!40000 ALTER TABLE `produccion` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `produccion_diaria`
--

DROP TABLE IF EXISTS `produccion_diaria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `produccion_diaria` (
  `id_pd` int NOT NULL AUTO_INCREMENT,
  `folio` varchar(20) NOT NULL,
  `nombre` varchar(120) NOT NULL COMMENT 'Nombre descriptivo, ej: Producción Mañanera Lunes',
  `estado` enum('pendiente','en_proceso','finalizado','cancelado') NOT NULL DEFAULT 'pendiente',
  `operario_id` int DEFAULT NULL,
  `total_cajas` int NOT NULL DEFAULT '0' COMMENT 'Deprecated v2 – siempre 0',
  `total_piezas_esperadas` int NOT NULL DEFAULT '0',
  `alerta_insumos` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1 si había faltantes al crear',
  `insumos_descontados` tinyint(1) NOT NULL DEFAULT '0',
  `inventario_acreditado` tinyint(1) NOT NULL DEFAULT '0',
  `observaciones` text,
  `motivo_cancelacion` text,
  `fecha_inicio` datetime DEFAULT NULL,
  `fecha_fin_real` datetime DEFAULT NULL,
  `creado_por` int DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_pd`),
  UNIQUE KEY `uq_pd_folio` (`folio`),
  KEY `idx_pd_estado_fecha` (`estado`,`creado_en`),
  KEY `idx_pd_operario` (`operario_id`),
  KEY `idx_pd_creado_por` (`creado_por`),
  CONSTRAINT `fk_pd_creado_por2` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `fk_pd_operario` FOREIGN KEY (`operario_id`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Encabezado de producción diaria para tienda física';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `produccion_diaria`
--

LOCK TABLES `produccion_diaria` WRITE;
/*!40000 ALTER TABLE `produccion_diaria` DISABLE KEYS */;
/*!40000 ALTER TABLE `produccion_diaria` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_pd_alerta_insumos_log` AFTER INSERT ON `produccion_diaria` FOR EACH ROW BEGIN
  -- Si se creó con alerta de insumos, advertir en log
  IF NEW.alerta_insumos = 1 THEN
    INSERT INTO logs_sistema
      (tipo, nivel, id_usuario, modulo, accion, descripcion,
       referencia_id, referencia_tipo, creado_en)
    VALUES
      ('produccion', 'WARNING', NEW.creado_por, 'ProduccionDiaria',
       'alerta_insumos',
       CONCAT('Producción ', NEW.folio,
              ' creada con alerta de insumos insuficientes.'),
       NEW.id_pd, 'produccion_diaria', NOW());
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_pd_estado_log` AFTER UPDATE ON `produccion_diaria` FOR EACH ROW BEGIN
  -- Registra en logs_sistema cuando cambia el estado
  IF NEW.estado <> OLD.estado THEN
    INSERT INTO logs_sistema
      (tipo, nivel, id_usuario, modulo, accion, descripcion,
       referencia_id, referencia_tipo, creado_en)
    VALUES
      ('produccion', 'INFO', NEW.creado_por, 'ProduccionDiaria',
       CONCAT('estado_', NEW.estado),
       CONCAT('Producción ', NEW.folio, ' cambió de "', OLD.estado,
              '" a "', NEW.estado, '"'),
       NEW.id_pd, 'produccion_diaria', NOW());
  END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `produccion_diaria_detalle`
--

DROP TABLE IF EXISTS `produccion_diaria_detalle`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `produccion_diaria_detalle` (
  `id_pdd` int NOT NULL AUTO_INCREMENT,
  `id_pd` int NOT NULL,
  `id_producto` int NOT NULL,
  `id_receta` int NOT NULL,
  `cantidad_piezas` int NOT NULL COMMENT 'Piezas de este producto a producir',
  PRIMARY KEY (`id_pdd`),
  KEY `idx_pdd_pd` (`id_pd`),
  KEY `idx_pdd_prod` (`id_producto`),
  KEY `idx_pdd_receta` (`id_receta`),
  CONSTRAINT `fk_pdd_pd` FOREIGN KEY (`id_pd`) REFERENCES `produccion_diaria` (`id_pd`) ON DELETE CASCADE,
  CONSTRAINT `fk_pdd_prod` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`),
  CONSTRAINT `fk_pdd_receta` FOREIGN KEY (`id_receta`) REFERENCES `recetas` (`id_receta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Líneas de cajas en una producción diaria';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `produccion_diaria_detalle`
--

LOCK TABLES `produccion_diaria_detalle` WRITE;
/*!40000 ALTER TABLE `produccion_diaria_detalle` DISABLE KEYS */;
/*!40000 ALTER TABLE `produccion_diaria_detalle` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `produccion_diaria_insumos`
--

DROP TABLE IF EXISTS `produccion_diaria_insumos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `produccion_diaria_insumos` (
  `id_pdi` int NOT NULL AUTO_INCREMENT,
  `id_pd` int NOT NULL,
  `id_materia` int NOT NULL,
  `cantidad_requerida` decimal(12,4) NOT NULL,
  `cantidad_descontada` decimal(12,4) NOT NULL DEFAULT '0.0000',
  PRIMARY KEY (`id_pdi`),
  UNIQUE KEY `uq_pdi_pm` (`id_pd`,`id_materia`),
  KEY `idx_pdi_pd` (`id_pd`),
  KEY `idx_pdi_mat` (`id_materia`),
  CONSTRAINT `fk_pdi_mat` FOREIGN KEY (`id_materia`) REFERENCES `materias_primas` (`id_materia`),
  CONSTRAINT `fk_pdi_pd` FOREIGN KEY (`id_pd`) REFERENCES `produccion_diaria` (`id_pd`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Insumos totales de una producción diaria';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `produccion_diaria_insumos`
--

LOCK TABLES `produccion_diaria_insumos` WRITE;
/*!40000 ALTER TABLE `produccion_diaria_insumos` DISABLE KEYS */;
/*!40000 ALTER TABLE `produccion_diaria_insumos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `produccion_diaria_linea_prod`
--

DROP TABLE IF EXISTS `produccion_diaria_linea_prod`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `produccion_diaria_linea_prod` (
  `id_pdlp` int NOT NULL AUTO_INCREMENT,
  `id_pdd` int NOT NULL,
  `id_producto` int NOT NULL,
  `id_receta` int NOT NULL COMMENT 'Receta usada (producto + tamaño correcto)',
  `piezas_por_caja` tinyint NOT NULL COMMENT 'Cantidad de piezas de este producto en CADA caja',
  PRIMARY KEY (`id_pdlp`),
  KEY `idx_pdlp_pdd` (`id_pdd`),
  KEY `idx_pdlp_prod` (`id_producto`),
  KEY `idx_pdlp_receta` (`id_receta`),
  CONSTRAINT `fk_pdlp_pdd` FOREIGN KEY (`id_pdd`) REFERENCES `produccion_diaria_detalle` (`id_pdd`) ON DELETE CASCADE,
  CONSTRAINT `fk_pdlp_prod` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`),
  CONSTRAINT `fk_pdlp_receta` FOREIGN KEY (`id_receta`) REFERENCES `recetas` (`id_receta`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Productos concretos por línea de caja';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `produccion_diaria_linea_prod`
--

LOCK TABLES `produccion_diaria_linea_prod` WRITE;
/*!40000 ALTER TABLE `produccion_diaria_linea_prod` DISABLE KEYS */;
/*!40000 ALTER TABLE `produccion_diaria_linea_prod` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos`
--

DROP TABLE IF EXISTS `productos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos` (
  `id_producto` int NOT NULL AUTO_INCREMENT,
  `uuid_producto` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `nombre` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `descripcion` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `imagen_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Ruta relativa desde static/: uploads/productos/<uuid>.webp',
  `precio_venta` decimal(10,2) NOT NULL DEFAULT '0.00',
  `estatus` enum('activo','inactivo') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'activo',
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `actualizado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `creado_por` int DEFAULT NULL,
  PRIMARY KEY (`id_producto`),
  UNIQUE KEY `uq_uuid_producto` (`uuid_producto`),
  KEY `fk_prod_creado_por` (`creado_por`),
  KEY `idx_productos_imagen` (`imagen_url`(50)),
  KEY `idx_prod_nombre` (`nombre`),
  KEY `idx_prod_estatus` (`estatus`),
  CONSTRAINT `fk_prod_creado_por` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Catálogo de productos terminados (datos estáticos).';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos`
--

LOCK TABLES `productos` WRITE;
/*!40000 ALTER TABLE `productos` DISABLE KEYS */;
INSERT INTO `productos` VALUES (1,'84e8ac4f-2613-11f1-9474-c01850d072b8','Concha de Crema Pastelera','Concha suave rellena de crema pastelera clásica','uploads/productos/6910200044964811b2115dd630b96598.webp',30.00,'activo','2026-03-22 11:21:10','2026-04-14 09:17:07',NULL),(2,'84e8d2df-2613-11f1-9474-c01850d072b8','Concha de Chocolate','Concha de cocoa rellena de crema de chocolate','uploads/productos/bae2af7569c5438787e9d2b85af48462.webp',26.00,'activo','2026-03-22 11:21:10','2026-04-12 18:19:29',NULL),(3,'84e8d5db-2613-11f1-9474-c01850d072b8','Cuernito de Cajeta y Queso','Cuernito hojaldrado relleno de cajeta y queso crema','uploads/productos/9f26775a346441a695892bd59fde5bb5.webp',26.00,'activo','2026-03-22 11:21:10','2026-04-12 18:26:36',NULL),(4,'84e8d72f-2613-11f1-9474-c01850d072b8','Dona de Crema de Avellana','Dona con glaseado de chocolate rellena de crema de avellana','uploads/productos/34a23ece834748c09595291f5afb82db.webp',28.00,'activo','2026-03-22 11:21:10','2026-04-12 18:33:36',NULL),(5,'84e8d842-2613-11f1-9474-c01850d072b8','Cuernito de Dulce de Leche','Cuernito hojaldrado relleno de dulce de leche','uploads/productos/0d81b351cfb24e419f3470f9fde6497b.webp',25.00,'activo','2026-03-22 11:21:10','2026-04-12 18:29:54',NULL),(6,'84e8d976-2613-11f1-9474-c01850d072b8','Polvorón de Crema de Limón','Polvorón de mantequilla relleno de crema de limón','uploads/productos/9cd95bd9da0a4657a7913c6ac1ef16ed.webp',26.00,'activo','2026-03-22 11:21:10','2026-04-12 18:37:56',NULL),(7,'84e8da8e-2613-11f1-9474-c01850d072b8','Trenza de Canela y Piloncillo','Trenza de masa dulce rellena de piloncillo y canela','uploads/productos/744e67025b564d7e8d44cb8e359b2c23.webp',24.00,'activo','2026-03-22 11:21:10','2026-04-12 18:38:56',NULL),(8,'84e8dbb3-2613-11f1-9474-c01850d072b8','Volcán de Chocolate','Pan individual de cocoa con centro de crema de chocolate','uploads/productos/3668cd2d826346db9b1cf726c47437c6.webp',30.00,'activo','2026-03-22 11:21:10','2026-04-12 18:39:32',NULL),(9,'84e8dd04-2613-11f1-9474-c01850d072b8','Mogote de Requesón y Vainilla','Pan redondo esponjoso relleno de requesón con vainilla','uploads/productos/b55469d046f74c618718faee06ffbd59.webp',24.00,'activo','2026-03-22 11:21:10','2026-04-12 18:34:47',NULL),(10,'84e8de28-2613-11f1-9474-c01850d072b8','Dona de Mermelada de Fresa','Dona con azúcar glass rellena de mermelada de fresa','uploads/productos/ccfe66de7fa04b5fad626ac03701a853.webp',22.00,'activo','2026-03-22 11:21:10','2026-04-12 18:34:32',NULL),(11,'84e8df44-2613-11f1-9474-c01850d072b8','Cuernito de Crema Pastelera y Fresa','Cuernito hojaldrado con doble relleno de crema pastelera y fresa','uploads/productos/8aae76edad1d4975ad59079dd19f11f4.webp',28.00,'activo','2026-03-22 11:21:10','2026-04-12 18:27:24',NULL),(12,'84e8e05d-2613-11f1-9474-c01850d072b8','Brioche de Mantequilla y Azúcar Glass','Pan brioche relleno de mantequilla y cubierto de azúcar glass','uploads/productos/45dc80424cc142ba849b31c874059db0.webp',70.00,'activo','2026-03-22 11:21:10','2026-04-12 17:52:45',NULL),(14,'9e725390-e3f8-403f-95eb-9948a5f817c1','Bagget Relleno','Bagget con relleno de chocolates','uploads/productos/a863abdeae4e45bbb9821231abd5f8b7.webp',21.00,'activo','2026-03-31 15:48:33','2026-04-14 11:33:05',NULL),(15,'a9df1ce3-89e9-4475-bfa8-0727f2aaaac3','prueba imagen','prueba','uploads/productos/fb4d49ebc3a24722b69c99cfd8321ca7.webp',20.00,'activo','2026-04-09 13:47:03','2026-04-09 14:27:22',NULL);
/*!40000 ALTER TABLE `productos` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`dm_restore`@`localhost`*/ /*!50003 TRIGGER `trg_productos_imagen_audit` AFTER UPDATE ON `productos` FOR EACH ROW BEGIN
    
    IF NOT (OLD.imagen_url <=> NEW.imagen_url) THEN
        IF NEW.imagen_url IS NOT NULL THEN
            INSERT INTO log_imagen_producto
                (id_producto, imagen_ant, imagen_nueva, accion, cambiado_en)
            VALUES
                (NEW.id_producto, OLD.imagen_url, NEW.imagen_url, 'subida', NOW());
        ELSE
            INSERT INTO log_imagen_producto
                (id_producto, imagen_ant, imagen_nueva, accion, cambiado_en)
            VALUES
                (NEW.id_producto, OLD.imagen_url, NULL, 'eliminada', NOW());
        END IF;
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

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
  KEY `idx_prov_nombre` (`nombre`),
  KEY `idx_prov_estatus` (`estatus`),
  CONSTRAINT `proveedores_ibfk_1` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `proveedores`
--

LOCK TABLES `proveedores` WRITE;
/*!40000 ALTER TABLE `proveedores` DISABLE KEYS */;
INSERT INTO `proveedores` VALUES (1,'1fca251d-8aec-417e-bb87-c7e1a4712f04','Huevo Y Materias Primas Para Pan, Sa De Cv','EUTS0507LB8','Ricardo Flores','477-569-6964','ricardo@materiasprimas.com','Calle de las flores 123-A','activo','2026-03-31 15:19:08','2026-04-14 21:29:37',NULL),(2,'e70dc8ba-c9ba-4163-a051-285067735038','Industriamart','EUTS0507LB1','Carlos Perez','477 521 4769','carlos@industriamart.com','Avenida Miraflores 321','activo','2026-04-06 17:44:55','2026-04-06 17:45:13',NULL);
/*!40000 ALTER TABLE `proveedores` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`dm_restore`@`localhost`*/ /*!50003 TRIGGER `trg_prov_before_delete` BEFORE DELETE ON `proveedores` FOR EACH ROW BEGIN
    IF EXISTS (
        SELECT 1 FROM compras
        WHERE  id_proveedor = OLD.id_proveedor
        LIMIT  1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede eliminar un proveedor con compras registradas. Usa desactivar en su lugar.';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

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
  `id_tamanio` int DEFAULT NULL COMMENT 'Tamaño de charola al que corresponde esta receta. NULL = receta sin tamaño de charola.',
  PRIMARY KEY (`id_receta`),
  UNIQUE KEY `uuid_receta` (`uuid_receta`),
  UNIQUE KEY `uq_producto_tamanio` (`id_producto`,`id_tamanio`),
  KEY `creado_por` (`creado_por`),
  KEY `fk_receta_producto` (`id_producto`),
  KEY `fk_receta_tamanio` (`id_tamanio`),
  KEY `idx_recetas_producto_estatus` (`id_producto`,`estatus`),
  KEY `idx_rec_nombre` (`nombre`),
  KEY `idx_rec_estatus` (`estatus`),
  CONSTRAINT `fk_receta_producto` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`) ON DELETE SET NULL,
  CONSTRAINT `fk_receta_tamanio` FOREIGN KEY (`id_tamanio`) REFERENCES `tamanios_charola` (`id_tamanio`) ON DELETE SET NULL,
  CONSTRAINT `recetas_ibfk_1` FOREIGN KEY (`creado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=65 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `recetas`
--

LOCK TABLES `recetas` WRITE;
/*!40000 ALTER TABLE `recetas` DISABLE KEYS */;
INSERT INTO `recetas` VALUES (17,1,'47535891-2959-11f1-828b-c01850d072b8','Concha Crema Pastelera — Charola Chica','Charola de 4 conchas rellenas de crema pastelera',20.00,'pza',96.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(18,1,'475364c3-2959-11f1-828b-c01850d072b8','Concha Crema Pastelera — Charola Mediana','Charola de 8 conchas rellenas de crema pastelera',30.00,'pza',192.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(19,1,'475366d7-2959-11f1-828b-c01850d072b8','Concha Crema Pastelera — Charola Grande','Charola de 12 conchas rellenas de crema pastelera',40.00,'pza',288.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(20,2,'475653c0-2959-11f1-828b-c01850d072b8','Concha Chocolate — Charola Chica','Charola de 4 conchas de chocolate',20.00,'pza',104.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(21,2,'47566302-2959-11f1-828b-c01850d072b8','Concha Chocolate — Charola Mediana','Charola de 8 conchas de chocolate',30.00,'pza',208.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(22,2,'47566736-2959-11f1-828b-c01850d072b8','Concha Chocolate — Charola Grande','Charola de 12 conchas de chocolate',40.00,'pza',312.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(23,3,'4759dafa-2959-11f1-828b-c01850d072b8','Cuernito Cajeta Queso — Charola Chica','Charola de 4 cuernitos de cajeta y queso',20.00,'pza',104.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(24,3,'4759e3c0-2959-11f1-828b-c01850d072b8','Cuernito Cajeta Queso — Charola Mediana','Charola de 8 cuernitos de cajeta y queso',30.00,'pza',208.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(25,3,'4759e64f-2959-11f1-828b-c01850d072b8','Cuernito Cajeta Queso — Charola Grande','Charola de 12 cuernitos de cajeta y queso',40.00,'pza',312.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(26,4,'475d144c-2959-11f1-828b-c01850d072b8','Dona Avellana — Charola Chica','Charola de 4 donas de crema de avellana',20.00,'pza',112.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(27,4,'475d1dd4-2959-11f1-828b-c01850d072b8','Dona Avellana — Charola Mediana','Charola de 8 donas de crema de avellana',30.00,'pza',224.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(28,4,'475d1fe2-2959-11f1-828b-c01850d072b8','Dona Avellana — Charola Grande','Charola de 12 donas de crema de avellana',40.00,'pza',336.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(29,5,'47699731-2959-11f1-828b-c01850d072b8','Cuernito Dulce de Leche — Charola Chica','Charola de 4 cuernitos de dulce de leche',20.00,'pza',100.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(30,5,'4769a279-2959-11f1-828b-c01850d072b8','Cuernito Dulce de Leche — Charola Mediana','Charola de 8 cuernitos de dulce de leche',30.00,'pza',200.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(31,5,'4769a500-2959-11f1-828b-c01850d072b8','Cuernito Dulce de Leche — Charola Grande','Charola de 12 cuernitos de dulce de leche',40.00,'pza',300.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(32,6,'4774ff13-2959-11f1-828b-c01850d072b8','Polvorón Limón — Charola Chica','Charola de 4 polvorones de crema de limón',20.00,'pza',104.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(33,6,'477c63e6-2959-11f1-828b-c01850d072b8','Polvorón Limón — Charola Mediana','Charola de 8 polvorones de crema de limón',30.00,'pza',208.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(34,6,'477c68e8-2959-11f1-828b-c01850d072b8','Polvorón Limón — Charola Grande','Charola de 12 polvorones de crema de limón',40.00,'pza',312.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(35,7,'4783ea3e-2959-11f1-828b-c01850d072b8','Trenza Canela Piloncillo — Charola Chica','Charola de 4 trenzas de canela y piloncillo',20.00,'pza',96.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(36,7,'4783f244-2959-11f1-828b-c01850d072b8','Trenza Canela Piloncillo — Charola Mediana','Charola de 8 trenzas de canela y piloncillo',30.00,'pza',192.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(37,7,'4783f426-2959-11f1-828b-c01850d072b8','Trenza Canela Piloncillo — Charola Grande','Charola de 12 trenzas de canela y piloncillo',40.00,'pza',288.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(38,8,'47865367-2959-11f1-828b-c01850d072b8','Volcán Chocolate — Charola Chica','Charola de 4 volcanes de chocolate',20.00,'pza',120.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(39,8,'47865b53-2959-11f1-828b-c01850d072b8','Volcán Chocolate — Charola Mediana','Charola de 8 volcanes de chocolate',30.00,'pza',240.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(40,8,'47865d17-2959-11f1-828b-c01850d072b8','Volcán Chocolate — Charola Grande','Charola de 12 volcanes de chocolate',40.00,'pza',360.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(41,9,'47895029-2959-11f1-828b-c01850d072b8','Mogote Requesón — Charola Chica','Charola de 4 mogotes de requesón y vainilla',20.00,'pza',96.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(42,9,'478959d3-2959-11f1-828b-c01850d072b8','Mogote Requesón — Charola Mediana','Charola de 8 mogotes de requesón y vainilla',30.00,'pza',192.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(43,9,'47895cff-2959-11f1-828b-c01850d072b8','Mogote Requesón — Charola Grande','Charola de 12 mogotes de requesón y vainilla',40.00,'pza',288.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(44,10,'478d8985-2959-11f1-828b-c01850d072b8','Dona Fresa — Charola Chica','Charola de 4 donas de mermelada de fresa',20.00,'pza',88.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(45,10,'478d962e-2959-11f1-828b-c01850d072b8','Dona Fresa — Charola Mediana','Charola de 8 donas de mermelada de fresa',30.00,'pza',176.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(46,10,'478d98ba-2959-11f1-828b-c01850d072b8','Dona Fresa — Charola Grande','Charola de 12 donas de mermelada de fresa',40.00,'pza',264.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(47,11,'47924c0c-2959-11f1-828b-c01850d072b8','Cuernito C.Pastelera Fresa — Charola Chica','Charola de 4 cuernitos de crema pastelera y fresa',20.00,'pza',112.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,1),(48,11,'4792555b-2959-11f1-828b-c01850d072b8','Cuernito C.Pastelera Fresa — Charola Mediana','Charola de 8 cuernitos de crema pastelera y fresa',30.00,'pza',224.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(49,11,'479258e4-2959-11f1-828b-c01850d072b8','Cuernito C.Pastelera Fresa — Charola Grande','Charola de 12 cuernitos de crema pastelera y fresa',40.00,'pza',336.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(50,12,'4794cf24-2959-11f1-828b-c01850d072b8','Brioche Mantequilla — Charola Chica','Charola de 4 brioches de mantequilla y azúcar glass',20.00,'pza',80.00,'activo','2026-03-26 15:18:05','2026-04-06 23:25:37',1,1),(51,12,'4794d82a-2959-11f1-828b-c01850d072b8','Brioche Mantequilla — Charola Mediana','Charola de 8 brioches de mantequilla y azúcar glass',30.00,'pza',160.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,2),(52,12,'4794da3a-2959-11f1-828b-c01850d072b8','Brioche Mantequilla — Charola Grande','Charola de 12 brioches de mantequilla y azúcar glass',40.00,'pza',240.00,'activo','2026-03-26 15:18:05','2026-03-26 15:18:05',1,3),(53,1,'8190eb77-2c6e-11f1-828b-c01850d072b8','Concha Crema Pastelera — Media Grande','Media charola grande: 6 conchas de crema pastelera',20.00,'pza',144.00,'activo','2026-03-30 13:27:35','2026-03-30 13:27:35',1,NULL),(54,2,'8194dcdf-2c6e-11f1-828b-c01850d072b8','Concha Chocolate — Media Grande','Media charola grande: 6 conchas de chocolate',30.00,'pza',156.00,'activo','2026-03-30 13:27:35','2026-03-30 13:27:35',1,NULL),(55,3,'81971908-2c6e-11f1-828b-c01850d072b8','Cuernito Cajeta Queso — Media Grande','Media charola grande: 6 cuernitos de cajeta y queso',6.00,'pza',156.00,'activo','2026-03-30 13:27:35','2026-03-30 13:27:35',1,NULL),(56,4,'8198e284-2c6e-11f1-828b-c01850d072b8','Dona Avellana — Media Grande','Media charola grande: 6 donas de crema de avellana',6.00,'pza',168.00,'activo','2026-03-30 13:27:35','2026-03-30 13:27:35',1,NULL),(57,5,'819aa2c9-2c6e-11f1-828b-c01850d072b8','Cuernito Dulce de Leche — Media Grande','Media charola grande: 6 cuernitos de dulce de leche',6.00,'pza',150.00,'activo','2026-03-30 13:27:35','2026-03-30 13:27:35',1,NULL),(58,6,'819cc176-2c6e-11f1-828b-c01850d072b8','Polvorón Limón — Media Grande','Media charola grande: 6 polvorones de crema de limón',6.00,'pza',156.00,'activo','2026-03-30 13:27:35','2026-03-30 13:27:35',1,NULL),(59,7,'819ee3b1-2c6e-11f1-828b-c01850d072b8','Trenza Canela Piloncillo — Media Grande','Media charola grande: 6 trenzas de canela y piloncillo',6.00,'pza',144.00,'activo','2026-03-30 13:27:35','2026-03-30 13:27:35',1,NULL),(60,8,'81a0e6e4-2c6e-11f1-828b-c01850d072b8','Volcán Chocolate — Media Grande','Media charola grande: 6 volcanes de chocolate',6.00,'pza',180.00,'activo','2026-03-30 13:27:35','2026-03-30 13:27:35',1,NULL),(61,9,'81a29546-2c6e-11f1-828b-c01850d072b8','Mogote Requesón — Media Grande','Media charola grande: 6 mogotes de requesón y vainilla',6.00,'pza',144.00,'activo','2026-03-30 13:27:35','2026-03-30 13:27:35',1,NULL),(62,10,'81a45351-2c6e-11f1-828b-c01850d072b8','Dona Fresa — Media Grande','Media charola grande: 6 donas de mermelada de fresa',6.00,'pza',132.00,'activo','2026-03-30 13:27:35','2026-03-30 13:27:35',1,NULL),(63,11,'81a625d6-2c6e-11f1-828b-c01850d072b8','Cuernito C.Pastelera Fresa — Media Grande','Media charola grande: 6 cuernitos de crema pastelera y fresa',6.00,'pza',168.00,'activo','2026-03-30 13:27:35','2026-03-30 13:27:35',1,NULL),(64,12,'81a7be39-2c6e-11f1-828b-c01850d072b8','Brioche Mantequilla — Media Grande','Media charola grande: 6 brioches de mantequilla y azúcar glass',6.00,'pza',120.00,'activo','2026-03-30 13:27:35','2026-03-30 13:27:35',1,NULL);
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
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,'admin','Administrador','Acceso total al sistema'),(2,'empleado','Empleado','Acceso general de empleado'),(3,'panadero','Panadero','Acceso a módulos de producción'),(4,'cliente','Cliente','Acceso al portal de pedidos en línea');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `salida_inventario_lote`
--

DROP TABLE IF EXISTS `salida_inventario_lote`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `salida_inventario_lote` (
  `id_salida` int NOT NULL AUTO_INCREMENT,
  `id_lote` int NOT NULL,
  `id_receta` int NOT NULL,
  `id_producto` int NOT NULL,
  `piezas_producidas` int NOT NULL,
  PRIMARY KEY (`id_salida`),
  UNIQUE KEY `uq_salida_lote_producto` (`id_lote`,`id_producto`),
  KEY `id_receta` (`id_receta`),
  KEY `id_producto` (`id_producto`),
  CONSTRAINT `salida_inventario_lote_ibfk_1` FOREIGN KEY (`id_lote`) REFERENCES `lotes_produccion_caja` (`id_lote`) ON DELETE CASCADE,
  CONSTRAINT `salida_inventario_lote_ibfk_2` FOREIGN KEY (`id_receta`) REFERENCES `recetas` (`id_receta`),
  CONSTRAINT `salida_inventario_lote_ibfk_3` FOREIGN KEY (`id_producto`) REFERENCES `productos` (`id_producto`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `salida_inventario_lote`
--

LOCK TABLES `salida_inventario_lote` WRITE;
/*!40000 ALTER TABLE `salida_inventario_lote` DISABLE KEYS */;
/*!40000 ALTER TABLE `salida_inventario_lote` ENABLE KEYS */;
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
  `id_compra` int DEFAULT NULL,
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
  KEY `fk_salida_compra` (`id_compra`),
  KEY `idx_salidas_estado_fecha` (`estado`,`fecha_salida`),
  CONSTRAINT `fk_salida_compra` FOREIGN KEY (`id_compra`) REFERENCES `compras` (`id_compra`) ON DELETE SET NULL,
  CONSTRAINT `salidas_efectivo_ibfk_1` FOREIGN KEY (`aprobado_por`) REFERENCES `usuarios` (`id_usuario`) ON DELETE SET NULL,
  CONSTRAINT `salidas_efectivo_ibfk_2` FOREIGN KEY (`id_corte`) REFERENCES `cortes_diarios` (`id_corte`) ON DELETE SET NULL,
  CONSTRAINT `salidas_efectivo_ibfk_3` FOREIGN KEY (`id_proveedor`) REFERENCES `proveedores` (`id_proveedor`) ON DELETE SET NULL,
  CONSTRAINT `salidas_efectivo_ibfk_4` FOREIGN KEY (`registrado_por`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `salidas_efectivo`
--

LOCK TABLES `salidas_efectivo` WRITE;
/*!40000 ALTER TABLE `salidas_efectivo` DISABLE KEYS */;
INSERT INTO `salidas_efectivo` VALUES (1,'SE-0001',1,1,'compra_insumos','Pago pedido compra C-0001',254.00,'2026-04-06','aprobada',NULL,1,1,'2026-04-06 17:52:05','2026-04-06 19:11:57'),(2,'SE-0002',2,2,'compra_insumos','Pago pedido compra C-0002',205.00,'2026-04-06','aprobada',NULL,1,1,'2026-04-06 19:21:20','2026-04-06 19:21:40'),(3,'SE-0003',1,3,'compra_insumos','Pago pedido compra C-0003',4385.00,'2026-04-06','pendiente',NULL,1,NULL,'2026-04-06 19:32:35','2026-04-06 19:32:35'),(4,'SE-0004',1,4,'compra_insumos','Pago pedido compra C-0004',84.00,'2026-04-09','pendiente',NULL,1,NULL,'2026-04-09 11:39:42','2026-04-09 11:39:42');
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
-- Table structure for table `tamanios_charola`
--

DROP TABLE IF EXISTS `tamanios_charola`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tamanios_charola` (
  `id_tamanio` int NOT NULL AUTO_INCREMENT,
  `nombre` varchar(40) NOT NULL COMMENT 'Ej: Charola Chica, Charola Mediana, Charola Grande',
  `capacidad` tinyint NOT NULL COMMENT 'Número de panes que caben: 4, 8 o 12',
  `descripcion` text,
  `estatus` enum('activo','inactivo') NOT NULL DEFAULT 'activo',
  `creado_en` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_tamanio`),
  UNIQUE KEY `uq_capacidad` (`capacidad`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='Tamaños de charola disponibles para armar cajas de pan.';
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tamanios_charola`
--

LOCK TABLES `tamanios_charola` WRITE;
/*!40000 ALTER TABLE `tamanios_charola` DISABLE KEYS */;
INSERT INTO `tamanios_charola` VALUES (1,'Charola Chica',4,'Caja para 4 panes','activo','2026-03-26 14:27:32'),(2,'Charola Mediana',8,'Caja para 8 panes','activo','2026-03-26 14:27:32'),(3,'Charola Grande',12,'Caja para 12 panes','activo','2026-03-26 14:27:32');
/*!40000 ALTER TABLE `tamanios_charola` ENABLE KEYS */;
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
) ENGINE=InnoDB AUTO_INCREMENT=80 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `unidades_presentacion`
--

LOCK TABLES `unidades_presentacion` WRITE;
/*!40000 ALTER TABLE `unidades_presentacion` DISABLE KEYS */;
INSERT INTO `unidades_presentacion` VALUES (1,1,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(2,1,'Saco 25 kg','saco',25000.00,'compra',1,'2026-03-24 15:03:49'),(3,1,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(4,1,'Taza cernida','taza',120.00,'receta',1,'2026-03-24 15:03:49'),(5,2,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(6,2,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(7,2,'Cucharada','cda',12.00,'receta',1,'2026-03-24 15:03:49'),(8,2,'Taza','taza',200.00,'receta',1,'2026-03-24 15:03:49'),(9,3,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(10,3,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(11,3,'Barra 90 g','barra',90.00,'receta',1,'2026-03-24 15:03:49'),(12,3,'Cucharada','cda',14.00,'receta',1,'2026-03-24 15:03:49'),(13,4,'Galón (3.785 L)','gal',3785.00,'compra',1,'2026-03-24 15:03:49'),(14,4,'Litro','lt',1000.00,'ambos',1,'2026-03-24 15:03:49'),(15,4,'Taza (240 ml)','taza',240.00,'receta',1,'2026-03-24 15:03:49'),(16,4,'Mililitro','ml',1.00,'receta',1,'2026-03-24 15:03:49'),(17,5,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(18,5,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(19,5,'Cucharadita','cdta',3.00,'receta',1,'2026-03-24 15:03:49'),(20,6,'Kilo (16 pzas)','kg',16.00,'compra',1,'2026-03-24 15:03:49'),(21,6,'Docena','doc',12.00,'compra',1,'2026-03-24 15:03:49'),(22,6,'Caja 30 pzas','caja',30.00,'compra',1,'2026-03-24 15:03:49'),(23,6,'Pieza','pza',1.00,'receta',1,'2026-03-24 15:03:49'),(24,7,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(25,7,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(26,7,'Cucharadita','cdta',5.00,'receta',1,'2026-03-24 15:03:49'),(27,7,'Pizca','pizca',0.50,'receta',1,'2026-03-24 15:03:49'),(28,8,'Litro','lt',1000.00,'compra',1,'2026-03-24 15:03:49'),(29,8,'Mililitro','ml',1.00,'receta',1,'2026-03-24 15:03:49'),(30,8,'Cucharadita','cdta',5.00,'receta',1,'2026-03-24 15:03:49'),(31,9,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(32,9,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(33,9,'Cucharada','cda',7.00,'receta',1,'2026-03-24 15:03:49'),(34,9,'Taza','taza',85.00,'receta',1,'2026-03-24 15:03:49'),(35,10,'Bolsa 500 g','bolsa',500.00,'compra',1,'2026-03-24 15:03:49'),(36,10,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(37,10,'Cucharadita','cdta',2.50,'receta',1,'2026-03-24 15:03:49'),(38,10,'Cucharada','cda',7.00,'receta',1,'2026-03-24 15:03:49'),(39,11,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(40,11,'Barra 190 g','barra',190.00,'compra',1,'2026-03-24 15:03:49'),(41,11,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(42,11,'Cucharada','cda',15.00,'receta',1,'2026-03-24 15:03:49'),(43,12,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(44,12,'Frasco 500 g','frasco',500.00,'compra',1,'2026-03-24 15:03:49'),(45,12,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(46,12,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(47,13,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(48,13,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(49,13,'Cucharada','cda',25.00,'receta',1,'2026-03-24 15:03:49'),(50,14,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(51,14,'Frasco 370 g','frasco',370.00,'compra',1,'2026-03-24 15:03:49'),(52,14,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(53,14,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(54,15,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(55,15,'Frasco 400 g','frasco',400.00,'compra',1,'2026-03-24 15:03:49'),(56,15,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(57,15,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(58,16,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(59,16,'Frasco 450 g','frasco',450.00,'compra',1,'2026-03-24 15:03:49'),(60,16,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(61,16,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(62,17,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(63,17,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(64,17,'Cucharada','cda',20.00,'receta',1,'2026-03-24 15:03:49'),(65,18,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(66,18,'Cono 250 g','cono',250.00,'compra',1,'2026-03-24 15:03:49'),(67,18,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(68,18,'Cucharada','cda',12.00,'receta',1,'2026-03-24 15:03:49'),(69,19,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(70,19,'Barra 250 g','barra',250.00,'compra',1,'2026-03-24 15:03:49'),(71,19,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(72,19,'Cucharada','cda',25.00,'receta',1,'2026-03-24 15:03:49'),(73,20,'Kilogramo','kg',1000.00,'compra',1,'2026-03-24 15:03:49'),(74,20,'Bolsa 500 g','bolsa',500.00,'compra',1,'2026-03-24 15:03:49'),(75,20,'Gramo','g',1.00,'receta',1,'2026-03-24 15:03:49'),(76,20,'Cucharada','cda',10.00,'receta',1,'2026-03-24 15:03:49'),(77,20,'Taza','taza',120.00,'receta',1,'2026-03-24 15:03:49'),(78,10,'Costal 50','kg',50000.00,'compra',1,'2026-04-05 15:45:25'),(79,17,'Frasco 250g','frasc250',250.00,'compra',1,'2026-04-06 19:27:51');
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
  `telefono` varchar(20) DEFAULT NULL,
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
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (1,'1313435b-27e3-4ecc-b4ca-6628dd75813a','Salva - Admin',NULL,'ramirezjuanpablo536@gmail.com','scrypt:32768:8:1$5boE1EYf6tjrrS5W$6654106a3e5cd7f9e8b0f80fea8829cebbbfafdb6dd4525d9978b8ab98f385249d3f60e12c736cd44d0db0f4d9b0cfc9af7afd8dfff6bc176f4615332973b8ec',1,'activo',0,NULL,'2026-04-16 01:12:47',NULL,NULL,0,'2026-03-17 13:41:47','2026-04-16 01:12:47',NULL),(2,'a2cf04f0-823d-4d4f-abfa-c3ffd1821cc4','Salva - Panadero',NULL,'panadero','scrypt:32768:8:1$3YY1waWeDgejMlVO$ac4ed6e51536eaa0c6e8d67b2f85660e8c3a875589994585f439ae6dbc347d8097b82344dd59de032b45adf3b9561bf1e0a191b2f7bf1a55587e75f2b68dc5b8',3,'activo',0,NULL,'2026-04-14 20:55:26',NULL,NULL,0,'2026-03-25 17:46:04','2026-04-14 20:55:26',NULL),(3,'16d02607-469b-4e6f-a0d5-28b766436048','Salva - Cliente',NULL,'pabloescuela536@gmail.com','scrypt:32768:8:1$3YY1waWeDgejMlVO$ac4ed6e51536eaa0c6e8d67b2f85660e8c3a875589994585f439ae6dbc347d8097b82344dd59de032b45adf3b9561bf1e0a191b2f7bf1a55587e75f2b68dc5b8',4,'activo',0,NULL,'2026-04-14 20:50:26',NULL,NULL,0,'2026-03-26 11:17:47','2026-04-14 21:29:20',1),(5,'470048f6-63d4-49c9-b209-3ce4a7ebc7a6','Salva - Empleado',NULL,'empleado','scrypt:32768:8:1$3YY1waWeDgejMlVO$ac4ed6e51536eaa0c6e8d67b2f85660e8c3a875589994585f439ae6dbc347d8097b82344dd59de032b45adf3b9561bf1e0a191b2f7bf1a55587e75f2b68dc5b8',2,'activo',0,NULL,'2026-04-16 01:06:35',NULL,NULL,0,'2026-04-02 16:46:01','2026-04-16 01:06:35',1),(6,'2a442a9b-c83e-4771-a0e9-e55b7551bb76','Alfredo Afanador Ramirez',NULL,'casine1282@dwseal.com','scrypt:32768:8:1$ZEdymdbWIUEyR5b8$16879d1723b679a1d0c9421221ea6fad4b7fb9db40d734ab76a700d77b666cf2ce9dea442f3a6ee41f8aafdef8601525041dda000176162c243b4f7b1475d543',2,'activo',0,NULL,NULL,NULL,NULL,0,'2026-04-14 21:10:23','2026-04-16 01:43:57',1),(7,'c44d4d5c-55b2-4cd6-9fc0-de4051a75de0','Luis',NULL,'vahateb432@bmoar.com','scrypt:32768:8:1$i5UXwN95baQZ9AyT$f215fba1fa3d5acb64a109b235a8b6dc4de165ae4791fe8a1be6399ba66667095666dee3bac6c64b0bca542c071e6a2a16fdc8a236626e078dcd458c1ba97390',3,'activo',0,NULL,NULL,NULL,NULL,0,'2026-04-16 01:46:21','2026-04-16 01:46:46',1);
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `v_caja_pedido`
--

DROP TABLE IF EXISTS `v_caja_pedido`;
/*!50001 DROP VIEW IF EXISTS `v_caja_pedido`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_caja_pedido` AS SELECT 
 1 AS `id_pedido`,
 1 AS `tipo`,
 1 AS `tamanio`,
 1 AS `nombre_caja`,
 1 AS `capacidad`,
 1 AS `precio_venta`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_cajas_detalle`
--

DROP TABLE IF EXISTS `v_cajas_detalle`;
/*!50001 DROP VIEW IF EXISTS `v_cajas_detalle`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_cajas_detalle` AS SELECT 
 1 AS `id_caja`,
 1 AS `nombre_caja`,
 1 AS `tipo`,
 1 AS `tamanio`,
 1 AS `capacidad`,
 1 AS `precio_venta`,
 1 AS `estatus`,
 1 AS `productos`,
 1 AS `total_piezas`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_conteo_pedidos_por_estado`
--

DROP TABLE IF EXISTS `v_conteo_pedidos_por_estado`;
/*!50001 DROP VIEW IF EXISTS `v_conteo_pedidos_por_estado`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_conteo_pedidos_por_estado` AS SELECT 
 1 AS `estado`,
 1 AS `total`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_costo_promedio_materia`
--

DROP TABLE IF EXISTS `v_costo_promedio_materia`;
/*!50001 DROP VIEW IF EXISTS `v_costo_promedio_materia`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_costo_promedio_materia` AS SELECT 
 1 AS `id_materia`,
 1 AS `costo_base_promedio`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_detalle_pedido`
--

DROP TABLE IF EXISTS `v_detalle_pedido`;
/*!50001 DROP VIEW IF EXISTS `v_detalle_pedido`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_detalle_pedido` AS SELECT 
 1 AS `id_pedido`,
 1 AS `producto_nombre`,
 1 AS `producto_descripcion`,
 1 AS `cantidad`,
 1 AS `precio_unitario`,
 1 AS `subtotal`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_historial_pedido`
--

DROP TABLE IF EXISTS `v_historial_pedido`;
/*!50001 DROP VIEW IF EXISTS `v_historial_pedido`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_historial_pedido` AS SELECT 
 1 AS `id_pedido`,
 1 AS `estado_antes`,
 1 AS `estado_despues`,
 1 AS `nota`,
 1 AS `creado_en`,
 1 AS `usuario_nombre`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_notificaciones_cliente`
--

DROP TABLE IF EXISTS `v_notificaciones_cliente`;
/*!50001 DROP VIEW IF EXISTS `v_notificaciones_cliente`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_notificaciones_cliente` AS SELECT 
 1 AS `id_notif`,
 1 AS `id_pedido`,
 1 AS `id_usuario`,
 1 AS `folio`,
 1 AS `mensaje`,
 1 AS `leida`,
 1 AS `creado_en`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_pedido_detalle_completo`
--

DROP TABLE IF EXISTS `v_pedido_detalle_completo`;
/*!50001 DROP VIEW IF EXISTS `v_pedido_detalle_completo`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_pedido_detalle_completo` AS SELECT 
 1 AS `id_pedido`,
 1 AS `id_detalle`,
 1 AS `producto_nombre`,
 1 AS `producto_descripcion`,
 1 AS `cantidad`,
 1 AS `precio_unitario`,
 1 AS `subtotal`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_pedidos_resumen`
--

DROP TABLE IF EXISTS `v_pedidos_resumen`;
/*!50001 DROP VIEW IF EXISTS `v_pedidos_resumen`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_pedidos_resumen` AS SELECT 
 1 AS `id_pedido`,
 1 AS `folio`,
 1 AS `estado`,
 1 AS `fecha_recogida`,
 1 AS `total_estimado`,
 1 AS `motivo_rechazo`,
 1 AS `creado_en`,
 1 AS `actualizado_en`,
 1 AS `id_cliente`,
 1 AS `tipo_caja`,
 1 AS `tamanio_nombre`,
 1 AS `capacidad`,
 1 AS `id_usuario`,
 1 AS `cliente_nombre`,
 1 AS `cliente_username`,
 1 AS `num_productos`,
 1 AS `total_piezas`,
 1 AS `atendido_por_nombre`*/;
SET character_set_client = @saved_cs_client;

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
-- Temporary view structure for view `v_recetas_por_tamanio`
--

DROP TABLE IF EXISTS `v_recetas_por_tamanio`;
/*!50001 DROP VIEW IF EXISTS `v_recetas_por_tamanio`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_recetas_por_tamanio` AS SELECT 
 1 AS `id_receta`,
 1 AS `nombre_receta`,
 1 AS `nombre_producto`,
 1 AS `tamanio`,
 1 AS `piezas`,
 1 AS `rendimiento`,
 1 AS `ingrediente`,
 1 AS `cantidad_requerida`,
 1 AS `unidad`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `v_ultimo_costo_materia`
--

DROP TABLE IF EXISTS `v_ultimo_costo_materia`;
/*!50001 DROP VIEW IF EXISTS `v_ultimo_costo_materia`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_ultimo_costo_materia` AS SELECT 
 1 AS `id_materia`,
 1 AS `costo_por_unidad_base`,
 1 AS `unidad_compra`,
 1 AS `factor_conversion`,
 1 AS `costo_base`*/;
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
  KEY `idx_ventas_fecha` (`fecha_venta`),
  KEY `idx_ventas_estado_fecha` (`estado`,`fecha_venta`),
  KEY `idx_ventas_vendedor_fecha` (`vendedor_id`,`fecha_venta`),
  CONSTRAINT `ventas_ibfk_1` FOREIGN KEY (`id_corte`) REFERENCES `cortes_diarios` (`id_corte`) ON DELETE SET NULL,
  CONSTRAINT `ventas_ibfk_2` FOREIGN KEY (`vendedor_id`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ventas`
--

LOCK TABLES `ventas` WRITE;
/*!40000 ALTER TABLE `ventas` DISABLE KEYS */;
INSERT INTO `ventas` VALUES (1,'VTA-20260412-001','2026-04-12 16:26:31',112.00,'efectivo',0.00,1,'completada',1,NULL,'2026-04-12 16:26:31'),(2,'VTA-20260412-002','2026-04-12 20:11:01',312.00,'efectivo',0.00,1,'completada',1,NULL,'2026-04-12 20:11:01'),(3,'VTA-20260412-003','2026-04-12 20:11:33',72.00,'tarjeta',0.00,1,'completada',1,NULL,'2026-04-12 20:11:33'),(4,'VTA-20260412-004','2026-04-12 20:30:45',72.00,'efectivo',0.00,1,'completada',1,NULL,'2026-04-12 20:30:45');
/*!40000 ALTER TABLE `ventas` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`dm_restore`@`localhost`*/ /*!50003 TRIGGER `trg_venta_completada_log` AFTER UPDATE ON `ventas` FOR EACH ROW BEGIN
    
    IF NEW.estado = 'completada' AND OLD.estado != 'completada' THEN
        INSERT INTO logs_sistema
            (tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en)
        VALUES
            ('venta', 'INFO', NEW.vendedor_id, 'ventas', 'venta_completada',
             CONCAT('Venta completada: ', NEW.folio_venta,
                    ' | Total: $', NEW.total,
                    ' | Método: ', NEW.metodo_pago),
             NOW());
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Temporary view structure for view `vw_compras`
--

DROP TABLE IF EXISTS `vw_compras`;
/*!50001 DROP VIEW IF EXISTS `vw_compras`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_compras` AS SELECT 
 1 AS `id_compra`,
 1 AS `folio`,
 1 AS `folio_factura`,
 1 AS `id_proveedor`,
 1 AS `nombre_proveedor`,
 1 AS `fecha_compra`,
 1 AS `total`,
 1 AS `estatus`,
 1 AS `motivo_cancelacion`,
 1 AS `observaciones`,
 1 AS `creado_en`,
 1 AS `creado_por`,
 1 AS `estatus_pago`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_corte_ventas_dia`
--

DROP TABLE IF EXISTS `vw_corte_ventas_dia`;
/*!50001 DROP VIEW IF EXISTS `vw_corte_ventas_dia`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_corte_ventas_dia` AS SELECT 
 1 AS `origen`,
 1 AS `id_transaccion`,
 1 AS `folio`,
 1 AS `fecha`,
 1 AS `hora`,
 1 AS `total`,
 1 AS `metodo_pago`,
 1 AS `estado`,
 1 AS `vendedor`,
 1 AS `total_piezas`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_dash_mp_criticas`
--

DROP TABLE IF EXISTS `vw_dash_mp_criticas`;
/*!50001 DROP VIEW IF EXISTS `vw_dash_mp_criticas`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_dash_mp_criticas` AS SELECT 
 1 AS `id_materia`,
 1 AS `nombre`,
 1 AS `categoria`,
 1 AS `unidad_base`,
 1 AS `stock_actual`,
 1 AS `stock_minimo`,
 1 AS `pct_stock`,
 1 AS `nivel`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_dash_piezas_vendidas`
--

DROP TABLE IF EXISTS `vw_dash_piezas_vendidas`;
/*!50001 DROP VIEW IF EXISTS `vw_dash_piezas_vendidas`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_dash_piezas_vendidas` AS SELECT 
 1 AS `id_producto`,
 1 AS `cantidad`,
 1 AS `subtotal`,
 1 AS `fecha`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_dash_ventas_consolidadas`
--

DROP TABLE IF EXISTS `vw_dash_ventas_consolidadas`;
/*!50001 DROP VIEW IF EXISTS `vw_dash_ventas_consolidadas`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_dash_ventas_consolidadas` AS SELECT 
 1 AS `origen_id`,
 1 AS `origen_tipo`,
 1 AS `fecha`,
 1 AS `monto`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_materias_primas`
--

DROP TABLE IF EXISTS `vw_materias_primas`;
/*!50001 DROP VIEW IF EXISTS `vw_materias_primas`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_materias_primas` AS SELECT 
 1 AS `id_materia`,
 1 AS `uuid_materia`,
 1 AS `nombre`,
 1 AS `categoria`,
 1 AS `unidad_base`,
 1 AS `stock_actual`,
 1 AS `stock_minimo`,
 1 AS `estatus`,
 1 AS `creado_en`,
 1 AS `actualizado_en`,
 1 AS `nivel_stock`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_produccion_diaria`
--

DROP TABLE IF EXISTS `vw_produccion_diaria`;
/*!50001 DROP VIEW IF EXISTS `vw_produccion_diaria`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_produccion_diaria` AS SELECT 
 1 AS `id_pd`,
 1 AS `folio`,
 1 AS `nombre`,
 1 AS `estado`,
 1 AS `total_cajas`,
 1 AS `total_piezas_esperadas`,
 1 AS `alerta_insumos`,
 1 AS `insumos_descontados`,
 1 AS `inventario_acreditado`,
 1 AS `observaciones`,
 1 AS `motivo_cancelacion`,
 1 AS `fecha_inicio`,
 1 AS `fecha_fin_real`,
 1 AS `creado_en`,
 1 AS `actualizado_en`,
 1 AS `operario_id`,
 1 AS `operario`,
 1 AS `creado_por`,
 1 AS `creado_por_nombre`,
 1 AS `total_lineas`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_productos`
--

DROP TABLE IF EXISTS `vw_productos`;
/*!50001 DROP VIEW IF EXISTS `vw_productos`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_productos` AS SELECT 
 1 AS `id_producto`,
 1 AS `uuid_producto`,
 1 AS `nombre`,
 1 AS `descripcion`,
 1 AS `imagen_url`,
 1 AS `precio_venta`,
 1 AS `estatus`,
 1 AS `creado_en`,
 1 AS `actualizado_en`,
 1 AS `stock_actual`,
 1 AS `stock_minimo`,
 1 AS `total_recetas`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_productos_stock`
--

DROP TABLE IF EXISTS `vw_productos_stock`;
/*!50001 DROP VIEW IF EXISTS `vw_productos_stock`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_productos_stock` AS SELECT 
 1 AS `id_producto`,
 1 AS `uuid_producto`,
 1 AS `nombre`,
 1 AS `descripcion`,
 1 AS `imagen_url`,
 1 AS `precio_venta`,
 1 AS `estatus`,
 1 AS `stock_actual`,
 1 AS `stock_minimo`,
 1 AS `estado_stock`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_recetas`
--

DROP TABLE IF EXISTS `vw_recetas`;
/*!50001 DROP VIEW IF EXISTS `vw_recetas`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_recetas` AS SELECT 
 1 AS `id_receta`,
 1 AS `uuid_receta`,
 1 AS `nombre`,
 1 AS `descripcion`,
 1 AS `id_producto`,
 1 AS `producto_nombre`,
 1 AS `rendimiento`,
 1 AS `unidad_rendimiento`,
 1 AS `precio_venta`,
 1 AS `estatus`,
 1 AS `creado_en`,
 1 AS `actualizado_en`,
 1 AS `creado_por`,
 1 AS `total_insumos`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_salidas_efectivo`
--

DROP TABLE IF EXISTS `vw_salidas_efectivo`;
/*!50001 DROP VIEW IF EXISTS `vw_salidas_efectivo`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_salidas_efectivo` AS SELECT 
 1 AS `id_salida`,
 1 AS `folio_salida`,
 1 AS `id_proveedor`,
 1 AS `nombre_proveedor`,
 1 AS `id_compra`,
 1 AS `folio_compra`,
 1 AS `categoria`,
 1 AS `descripcion`,
 1 AS `monto`,
 1 AS `fecha_salida`,
 1 AS `estado`,
 1 AS `registrado_por`,
 1 AS `nombre_registrador`,
 1 AS `aprobado_por`,
 1 AS `nombre_aprobador`,
 1 AS `creado_en`,
 1 AS `actualizado_en`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_top_productos_vendidos`
--

DROP TABLE IF EXISTS `vw_top_productos_vendidos`;
/*!50001 DROP VIEW IF EXISTS `vw_top_productos_vendidos`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_top_productos_vendidos` AS SELECT 
 1 AS `id_producto`,
 1 AS `nombre`,
 1 AS `precio_venta`,
 1 AS `ventas_caja`,
 1 AS `ventas_web`,
 1 AS `total_vendido`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_usuarios`
--

DROP TABLE IF EXISTS `vw_usuarios`;
/*!50001 DROP VIEW IF EXISTS `vw_usuarios`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_usuarios` AS SELECT 
 1 AS `id_usuario`,
 1 AS `nombre_completo`,
 1 AS `telefono`,
 1 AS `username`,
 1 AS `id_rol`,
 1 AS `nombre_rol`,
 1 AS `clave_rol`,
 1 AS `estatus`,
 1 AS `ultimo_login`,
 1 AS `creado_en`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_ventas_caja`
--

DROP TABLE IF EXISTS `vw_ventas_caja`;
/*!50001 DROP VIEW IF EXISTS `vw_ventas_caja`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_ventas_caja` AS SELECT 
 1 AS `id_venta`,
 1 AS `folio_venta`,
 1 AS `fecha_venta`,
 1 AS `total`,
 1 AS `metodo_pago`,
 1 AS `cambio`,
 1 AS `estado`,
 1 AS `vendedor_id`,
 1 AS `vendedor_nombre`,
 1 AS `num_productos`,
 1 AS `total_piezas`,
 1 AS `total_venta`,
 1 AS `ticket_impreso`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_ventas_consolidadas`
--

DROP TABLE IF EXISTS `vw_ventas_consolidadas`;
/*!50001 DROP VIEW IF EXISTS `vw_ventas_consolidadas`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_ventas_consolidadas` AS SELECT 
 1 AS `origen`,
 1 AS `id`,
 1 AS `folio`,
 1 AS `fecha`,
 1 AS `total`,
 1 AS `metodo_pago`,
 1 AS `estado`,
 1 AS `responsable`,
 1 AS `pedido_origen`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping events for database 'dulce_migaja'
--

--
-- Dumping routines for database 'dulce_migaja'
--
/*!50003 DROP PROCEDURE IF EXISTS `sp_actualizar_imagen_producto` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_actualizar_imagen_producto`(
    IN p_id_producto  INT,
    IN p_imagen_url   VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    SELECT COUNT(*) INTO v_existe
      FROM productos
     WHERE id_producto = p_id_producto;

    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Producto no encontrado.';
    END IF;

    UPDATE productos
       SET imagen_url      = p_imagen_url,
           actualizado_en  = NOW()
     WHERE id_producto = p_id_producto;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_actualizar_perfil_cliente` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_actualizar_perfil_cliente`(
    IN p_id_usuario      INT,
    IN p_nombre_completo VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN p_username        VARCHAR(60)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN p_telefono        VARCHAR(20)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_id_usuario) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario no existe.';
    END IF;

    IF EXISTS (SELECT 1 FROM usuarios WHERE username = p_username AND id_usuario <> p_id_usuario) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de usuario ya esta en uso.';
    END IF;

    UPDATE usuarios
    SET nombre_completo = p_nombre_completo,
        username        = p_username,
        telefono        = p_telefono,
        actualizado_en  = NOW()
    WHERE id_usuario = p_id_usuario;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_agregar_detalle_compra` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_agregar_detalle_compra`(
    IN p_id_compra              INT,
    IN p_id_materia             INT,
    IN p_id_unidad_presentacion INT,      
    IN p_cantidad_comprada      DECIMAL(12,4),
    IN p_unidad_compra          VARCHAR(20) CHARACTER SET utf8mb4,
    IN p_factor_conversion      DECIMAL(12,4),
    IN p_cantidad_base          DECIMAL(12,4),
    IN p_costo_unitario         DECIMAL(12,4)
)
BEGIN
    
    IF NOT EXISTS (
        SELECT 1 FROM compras
        WHERE id_compra = p_id_compra AND estatus = 'ordenado'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se pueden agregar detalles a pedidos en estatus ordenado.';
    END IF;

    INSERT INTO detalle_compras (
        id_compra, id_materia, id_unidad_presentacion,
        cantidad_comprada, unidad_compra,
        factor_conversion, cantidad_base, costo_unitario
    ) VALUES (
        p_id_compra, p_id_materia,
        NULLIF(p_id_unidad_presentacion, 0),
        p_cantidad_comprada, p_unidad_compra,
        p_factor_conversion, p_cantidad_base, p_costo_unitario
    );

    
    UPDATE compras
    SET total = (
        SELECT COALESCE(SUM(cantidad_comprada * costo_unitario), 0)
        FROM detalle_compras
        WHERE id_compra = p_id_compra
    )
    WHERE id_compra = p_id_compra;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_aprobar_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_aprobar_pedido`(
  IN  p_folio  VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_user   INT,
  IN  p_nota   TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  OUT p_ok     TINYINT(1),
  OUT p_error  VARCHAR(300)
)
sp_main: BEGIN
  DECLARE v_id_pedido  INT;
  DECLARE v_estado     VARCHAR(30);
  DECLARE v_id_cliente INT;
  DECLARE v_id_prod    INT;
  DECLARE v_qty        DECIMAL(10,2);
  DECLARE v_stock      DECIMAL(12,2);
  DECLARE v_nombre     VARCHAR(120);
  DECLARE v_msg        VARCHAR(255);
  DECLARE done         INT DEFAULT 0;

  
  DECLARE cur_detalle CURSOR FOR
    SELECT dp.id_producto, dp.cantidad, p.nombre, COALESCE(i.stock_actual,0)
      FROM detalle_pedidos dp
      JOIN productos p ON p.id_producto = dp.id_producto
      LEFT JOIN inventario_pt i ON i.id_producto = dp.id_producto
     WHERE dp.id_pedido = v_id_pedido;

  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
  END;

  SET p_ok = 0; SET p_error = NULL;

  SELECT id_pedido, estado, id_cliente
    INTO v_id_pedido, v_estado, v_id_cliente
    FROM pedidos WHERE folio = p_folio LIMIT 1;

  IF v_id_pedido IS NULL THEN
    SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
    LEAVE sp_main;
  END IF;

  IF v_estado != 'pendiente' THEN
    SET p_error = CONCAT('Solo se pueden aprobar pedidos pendientes. Estado: ', v_estado);
    LEAVE sp_main;
  END IF;

  START TRANSACTION;

    
    OPEN cur_detalle;
    leer: LOOP
      FETCH cur_detalle INTO v_id_prod, v_qty, v_nombre, v_stock;
      IF done THEN LEAVE leer; END IF;

      IF v_stock < v_qty THEN
        SET v_msg = CONCAT('Stock insuficiente para "', v_nombre,
                           '". Disponible: ', FLOOR(v_stock), ' pzas.');
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
      END IF;

      UPDATE inventario_pt
         SET stock_actual = stock_actual - v_qty,
             ultima_actualizacion = NOW()
       WHERE id_producto = v_id_prod;
    END LOOP;
    CLOSE cur_detalle;

    UPDATE pedidos
       SET estado = 'aprobado', atendido_por = p_user, actualizado_en = NOW()
     WHERE id_pedido = v_id_pedido;

    INSERT INTO historial_pedidos
      (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
    VALUES
      (v_id_pedido, 'pendiente', 'aprobado', COALESCE(p_nota,'Pedido aprobado.'), p_user, NOW());

    INSERT INTO notificaciones_pedidos
      (id_pedido, id_usuario, folio, tipo, mensaje, leida, creado_en)
    VALUES
      (v_id_pedido, v_id_cliente, p_folio, 'aprobado',
       CONCAT('✅ Tu pedido ', p_folio, ' fue aprobado y está siendo preparado.'),
       0, NOW());

  COMMIT;
  SET p_ok = 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_aprobar_salida` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_aprobar_salida`(
    IN p_id_salida    INT,
    IN p_decision     VARCHAR(10),   
    IN p_aprobado_por INT
)
BEGIN
    DECLARE v_estado VARCHAR(10);

    SELECT estado INTO v_estado
    FROM salidas_efectivo
    WHERE id_salida = p_id_salida;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La salida de efectivo no existe.';
    END IF;

    IF v_estado <> 'pendiente' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se pueden gestionar salidas en estado pendiente.';
    END IF;

    IF p_decision NOT IN ('aprobada', 'rechazada') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Decisión no válida. Use aprobada o rechazada.';
    END IF;

    UPDATE salidas_efectivo
       SET estado         = p_decision,
           aprobado_por   = p_aprobado_por,
           actualizado_en = NOW()
     WHERE id_salida = p_id_salida;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_badge_notifs` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_badge_notifs`(IN p_usuario INT)
BEGIN
    SELECT COUNT(*) AS count
    FROM   notificaciones_pedidos
    WHERE  id_usuario = p_usuario AND leida = 0;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cambiar_estado_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_cambiar_estado_pedido`(
  IN  p_folio  VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_estado VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_user   INT,
  IN  p_nota   TEXT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
  OUT p_error  VARCHAR(255)
)
sp_main: BEGIN
  DECLARE v_id_pedido   INT;
  DECLARE v_estado_prev VARCHAR(20);
  DECLARE v_id_cliente  INT;

  SET p_error = NULL;

  SELECT id_pedido, estado, id_cliente
    INTO v_id_pedido, v_estado_prev, v_id_cliente
  FROM pedidos
  WHERE folio = p_folio
  LIMIT 1;

  IF v_id_pedido IS NULL THEN
    SET p_error = 'Pedido no encontrado.';
    LEAVE sp_main;
  END IF;

  UPDATE pedidos
  SET    estado         = p_estado,
         atendido_por   = p_user,
         motivo_rechazo = IF(p_estado = 'rechazado', p_nota, motivo_rechazo),
         actualizado_en = NOW()
  WHERE  id_pedido = v_id_pedido;

  INSERT INTO historial_pedidos
    (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
  VALUES
    (v_id_pedido, v_estado_prev, p_estado, p_nota, p_user, NOW());

  
  IF p_estado IN ('aprobado', 'rechazado', 'listo', 'entregado') THEN
    INSERT INTO notificaciones_pedidos
      (id_pedido, id_usuario, folio, tipo, mensaje, leida, creado_en)
    VALUES (
      v_id_pedido, v_id_cliente, p_folio, p_estado,
      CONCAT('Tu pedido ', p_folio, ' ahora está: ', REPLACE(p_estado, '_', ' ')),
      0, NOW()
    );
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cambiar_estatus_usuario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_cambiar_estatus_usuario`(
    IN  p_id_usuario     INT,
    IN  p_nuevo_estatus  VARCHAR(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_ejecutado_por  INT
)
BEGIN
    
    IF p_id_usuario = p_ejecutado_por AND p_nuevo_estatus <> 'activo' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No puedes desactivar tu propia cuenta.';
    END IF;

    
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_id_usuario) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario no existe.';
    END IF;

    UPDATE usuarios
    SET estatus        = p_nuevo_estatus,
        actualizado_en = NOW()
    WHERE id_usuario = p_id_usuario;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cambiar_password` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_cambiar_password`(
    IN p_id_usuario    INT,
    IN p_password_hash VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_id_usuario) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario no existe.';
    END IF;

    UPDATE usuarios
    SET password_hash  = p_password_hash,
        actualizado_en = NOW()
    WHERE id_usuario = p_id_usuario;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cancelar_compra` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_cancelar_compra`(
    IN p_id_compra          INT,
    IN p_motivo_cancelacion TEXT CHARACTER SET utf8mb4,
    IN p_ejecutado_por      INT
)
BEGIN
    DECLARE v_estatus VARCHAR(20);

    SELECT estatus INTO v_estatus
    FROM compras WHERE id_compra = p_id_compra;

    IF v_estatus IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El pedido de compra no existe.';
    END IF;

    IF v_estatus <> 'ordenado' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se pueden cancelar pedidos en estatus ordenado.';
    END IF;

    IF p_motivo_cancelacion IS NULL OR TRIM(p_motivo_cancelacion) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Debes indicar el motivo de cancelación.';
    END IF;

    UPDATE compras
    SET estatus            = 'cancelado',
        motivo_cancelacion = p_motivo_cancelacion
    WHERE id_compra = p_id_compra;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cancelar_orden_produccion` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_cancelar_orden_produccion`(
  IN  p_id_produccion INT,
  IN  p_cancelado_por INT,
  IN  p_motivo        VARCHAR(500),
  OUT p_ok            TINYINT(1),
  OUT p_mensaje       VARCHAR(500)
)
proc: BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;
  DECLARE v_folio  VARCHAR(20) DEFAULT NULL;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    SET p_mensaje = 'Error inesperado al cancelar la orden.';
  END;

  SET p_ok = 0;

  SELECT estado, folio_lote
    INTO v_estado, v_folio
    FROM produccion
   WHERE id_produccion = p_id_produccion
   LIMIT 1;

  IF v_estado IS NULL THEN
    SET p_mensaje = CONCAT('No existe la orden con id = ', p_id_produccion, '.');
    LEAVE proc;
  END IF;

  IF v_estado NOT IN ('pendiente', 'en_proceso') THEN
    SET p_mensaje = CONCAT('La orden ', v_folio, ' no puede cancelarse. ',
                           'Estado actual: ', v_estado,
                           '. Solo se pueden cancelar órdenes pendientes o en proceso.');
    LEAVE proc;
  END IF;

  START TRANSACTION;

  UPDATE produccion
     SET estado        = 'cancelado',
         observaciones = CONCAT(
           COALESCE(observaciones, ''),
           ' | CANCELADO: ', COALESCE(p_motivo, 'Sin motivo')
         )
   WHERE id_produccion = p_id_produccion;

  INSERT INTO logs_sistema (
    tipo, nivel, id_usuario, modulo, accion, descripcion,
    referencia_id, referencia_tipo, creado_en
  ) VALUES (
    'produccion', 'WARNING', p_cancelado_por, 'Produccion', 'cancelar_orden',
    CONCAT('Orden ', v_folio, ' cancelada. Motivo: ', COALESCE(p_motivo, 'Sin motivo')),
    p_id_produccion, 'produccion', NOW()
  );

  COMMIT;

  SET p_ok      = 1;
  SET p_mensaje = CONCAT('Orden ', v_folio, ' cancelada exitosamente.');
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_cancelar_venta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_cancelar_venta`(
    IN  p_id_venta    INT,
    IN  p_cancelado_por INT,
    OUT p_error       VARCHAR(255)
)
sp_main: BEGIN
    DECLARE v_estado    VARCHAR(20);
    DECLARE v_folio     VARCHAR(20);
    DECLARE v_id_prod   INT;
    DECLARE v_cantidad  DECIMAL(10,2);
    DECLARE v_done      INT DEFAULT 0;

    DECLARE cur_det CURSOR FOR
        SELECT id_producto, cantidad
        FROM   detalle_ventas
        WHERE  id_venta = p_id_venta;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
    END;

    SET p_error = NULL;

    SELECT estado, folio_venta INTO v_estado, v_folio
    FROM   ventas
    WHERE  id_venta = p_id_venta;

    IF v_estado IS NULL THEN
        SET p_error = 'Venta no encontrada.';
        LEAVE sp_main;
    END IF;

    IF v_estado != 'completada' THEN
        SET p_error = CONCAT('Solo se pueden cancelar ventas completadas. Estado actual: ', v_estado);
        LEAVE sp_main;
    END IF;

    START TRANSACTION;

    
    OPEN cur_det;
    loop_det: LOOP
        FETCH cur_det INTO v_id_prod, v_cantidad;
        IF v_done THEN LEAVE loop_det; END IF;

        UPDATE inventario_pt
        SET    stock_actual = stock_actual + v_cantidad
        WHERE  id_producto  = v_id_prod;
    END LOOP;
    CLOSE cur_det;

    
    UPDATE ventas
    SET    estado = 'cancelada'
    WHERE  id_venta = p_id_venta;

    
    INSERT INTO logs_sistema (tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en)
    VALUES ('venta', 'WARNING', p_cancelado_por, 'ventas', 'cancelar_venta',
            CONCAT('Venta cancelada: ', v_folio), NOW());

    COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_catalogo_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_catalogo_pedido`()
BEGIN
  
  SELECT id_tamanio, nombre, capacidad, descripcion
  FROM   tamanios_charola
  WHERE  estatus = 'activo'
  ORDER  BY capacidad;

  
  
  
  
  
  SELECT p.id_producto, p.nombre, p.descripcion, p.precio_venta
  FROM   productos p
  WHERE  p.estatus = 'activo'

    
    AND EXISTS (
      SELECT 1 FROM recetas r
      WHERE  r.id_producto = p.id_producto
        AND  r.estatus     = 'activo'
        AND  r.id_tamanio  = 1
    )
    
    AND EXISTS (
      SELECT 1 FROM recetas r
      WHERE  r.id_producto = p.id_producto
        AND  r.estatus     = 'activo'
        AND  r.id_tamanio  = 2
    )
    
    AND EXISTS (
      SELECT 1 FROM recetas r
      WHERE  r.id_producto = p.id_producto
        AND  r.estatus     = 'activo'
        AND  r.id_tamanio  = 3
    )
    
    AND EXISTS (
      SELECT 1 FROM recetas r
      WHERE  r.id_producto  = p.id_producto
        AND  r.estatus      = 'activo'
        AND  r.id_tamanio   IS NULL
        AND  r.rendimiento  = 6
    )

  ORDER BY p.nombre;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_catalogo_tienda` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_catalogo_tienda`()
BEGIN
  SELECT
    p.id_producto,
    p.uuid_producto,
    p.nombre,
    p.descripcion,
    p.precio_venta,
    COALESCE(i.stock_actual, 0)   AS stock_actual,
    COALESCE(i.stock_minimo, 0)   AS stock_minimo,
    CASE
      WHEN COALESCE(i.stock_actual, 0) = 0                         THEN 'agotado'
      WHEN COALESCE(i.stock_actual, 0) <= COALESCE(i.stock_minimo * 0.25, 3) THEN 'critico'
      WHEN COALESCE(i.stock_actual, 0) < COALESCE(i.stock_minimo, 0)         THEN 'bajo'
      ELSE 'ok'
    END                           AS nivel_stock,
    p.imagen_url
  FROM productos p
  LEFT JOIN inventario_pt i ON i.id_producto = p.id_producto
  WHERE p.estatus = 'activo'
  ORDER BY
    CASE WHEN COALESCE(i.stock_actual, 0) = 0 THEN 1 ELSE 0 END,
    p.nombre;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_catalogo_ventas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_catalogo_ventas`(
    IN p_busqueda VARCHAR(120)
)
BEGIN
    SELECT  p.id_producto,
            p.nombre,
            p.descripcion,
            p.precio_venta,
            COALESCE(i.stock_actual, 0)  AS stock_actual,
            COALESCE(i.stock_minimo, 0)  AS stock_minimo,
            CASE WHEN COALESCE(i.stock_actual, 0) <= 0              THEN 'agotado'
                 WHEN COALESCE(i.stock_actual, 0) <= COALESCE(i.stock_minimo, 0) THEN 'bajo'
                 ELSE 'disponible'
            END AS estado_stock
    FROM    productos    p
    LEFT JOIN inventario_pt i ON i.id_producto = p.id_producto
    WHERE   p.estatus = 'activo'
      AND   (p_busqueda IS NULL
             OR p_busqueda = ''
             OR CONVERT(p.nombre USING utf8mb4) COLLATE utf8mb4_unicode_ci LIKE CONCAT('%', p_busqueda, '%'))
    ORDER BY p.nombre;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_corregir_precio_compra` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_corregir_precio_compra`(
    IN p_id_compra     INT,
    IN p_folio_salida  VARCHAR(20) CHARACTER SET utf8mb4,
    IN p_ejecutado_por INT
)
BEGIN
    DECLARE v_estatus_pago VARCHAR(10);
    DECLARE v_folio        VARCHAR(20);
    DECLARE v_id_proveedor INT;
    DECLARE v_fecha        DATE;
    DECLARE v_nuevo_total  DECIMAL(12,2);

    
    SELECT folio, id_proveedor, fecha_compra
    INTO   v_folio, v_id_proveedor, v_fecha
    FROM   compras WHERE id_compra = p_id_compra;

    IF v_folio IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El pedido de compra no existe.';
    END IF;

    
    SELECT estado INTO v_estatus_pago
    FROM   salidas_efectivo
    WHERE  id_compra = p_id_compra
    ORDER BY id_salida DESC
    LIMIT 1;

    IF v_estatus_pago IS NULL OR v_estatus_pago <> 'rechazada' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se puede corregir el precio de compras con pago rechazado.';
    END IF;

    
    UPDATE compras
    SET total = (
        SELECT COALESCE(SUM(cantidad_comprada * costo_unitario), 0)
        FROM detalle_compras
        WHERE id_compra = p_id_compra
    )
    WHERE id_compra = p_id_compra;

    SELECT total INTO v_nuevo_total
    FROM   compras WHERE id_compra = p_id_compra;

    
    INSERT INTO salidas_efectivo (
        folio_salida, id_proveedor, id_compra, categoria,
        descripcion, monto, fecha_salida,
        estado, registrado_por, creado_en, actualizado_en
    ) VALUES (
        p_folio_salida,
        v_id_proveedor,
        p_id_compra,
        'compra_insumos',
        CONCAT('Pago corregido pedido ', v_folio),
        v_nuevo_total,
        v_fecha,
        'pendiente',
        p_ejecutado_por,
        NOW(),
        NOW()
    );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_corte_generar` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_corte_generar`(
    IN  p_fecha              DATE,
    IN  p_usuario_id         INT,
    IN  p_efectivo_declarado DECIMAL(12,2),
    OUT p_ok                 TINYINT,
    OUT p_mensaje            VARCHAR(200)
)
BEGIN
    DECLARE v_id_corte      INT           DEFAULT NULL;
    DECLARE v_estado_actual VARCHAR(10)   DEFAULT NULL;
    DECLARE v_num_ventas    INT           DEFAULT 0;
    DECLARE v_total         DECIMAL(12,2) DEFAULT 0;
    DECLARE v_piezas        DECIMAL(12,2) DEFAULT 0;
    DECLARE v_efectivo      DECIMAL(12,2) DEFAULT 0;
    DECLARE v_tarjeta       DECIMAL(12,2) DEFAULT 0;
    DECLARE v_transf        DECIMAL(12,2) DEFAULT 0;
    DECLARE v_cancelaciones INT           DEFAULT 0;
    DECLARE v_diferencia    DECIMAL(12,2) DEFAULT 0;
    DECLARE v_msg           VARCHAR(200);

    SELECT id_corte, estado
      INTO v_id_corte, v_estado_actual
      FROM cortes_diarios
     WHERE fecha_corte = p_fecha
     LIMIT 1;

    IF v_estado_actual = 'cerrado' THEN
        SET p_ok = 0;
        SET v_msg = 'El corte para esta fecha ya fue cerrado anteriormente.';
        SET p_mensaje = v_msg;
    ELSE
        SELECT
            COUNT(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci THEN 1 END),
            COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci THEN total END), 0),
            COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci THEN total_piezas END), 0),
            COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                               AND metodo_pago = 'efectivo' COLLATE utf8mb4_0900_ai_ci THEN total END), 0),
            COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                               AND metodo_pago = 'tarjeta' COLLATE utf8mb4_0900_ai_ci THEN total END), 0),
            COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                               AND metodo_pago = 'transferencia' COLLATE utf8mb4_0900_ai_ci THEN total END), 0),
            COUNT(CASE WHEN estado = 'cancelada' COLLATE utf8mb4_0900_ai_ci THEN 1 END)
        INTO
            v_num_ventas, v_total, v_piezas,
            v_efectivo,   v_tarjeta, v_transf,
            v_cancelaciones
        FROM vw_corte_ventas_dia
        WHERE fecha = p_fecha;

        SET v_diferencia = p_efectivo_declarado - v_efectivo;

        IF v_id_corte IS NULL THEN
            INSERT INTO cortes_diarios (
                fecha_corte, total_ventas, total_tickets, total_piezas,
                efectivo, efectivo_declarado, diferencia_efectivo,
                tarjeta, transferencia, cancelaciones,
                estado, cerrado_por, cerrado_en, creado_en
            ) VALUES (
                p_fecha, v_total, v_num_ventas, v_piezas,
                v_efectivo, p_efectivo_declarado, v_diferencia,
                v_tarjeta, v_transf, v_cancelaciones,
                'cerrado', p_usuario_id, NOW(), NOW()
            );
            SET v_id_corte = LAST_INSERT_ID();
        ELSE
            UPDATE cortes_diarios
               SET total_ventas        = v_total,
                   total_tickets       = v_num_ventas,
                   total_piezas        = v_piezas,
                   efectivo            = v_efectivo,
                   efectivo_declarado  = p_efectivo_declarado,
                   diferencia_efectivo = v_diferencia,
                   tarjeta             = v_tarjeta,
                   transferencia       = v_transf,
                   cancelaciones       = v_cancelaciones,
                   estado              = 'cerrado',
                   cerrado_por         = p_usuario_id,
                   cerrado_en          = NOW()
             WHERE id_corte = v_id_corte;
        END IF;

        UPDATE ventas
           SET id_corte = v_id_corte
         WHERE DATE(fecha_venta) = p_fecha
           AND estado            = 'completada'
           AND id_corte          IS NULL;

        INSERT INTO logs_sistema
            (tipo, nivel, id_usuario, modulo, accion, descripcion,
             referencia_id, referencia_tipo, creado_en)
        VALUES
            ('venta', 'INFO', p_usuario_id, 'corte', 'corte_generado',
             CONCAT('Corte cerrado | Dif: $', v_diferencia, 
                    ' | Teórico: $', v_efectivo, 
                    ' | Declarado: $', p_efectivo_declarado),
             v_id_corte, 'corte', NOW());

        SET p_ok = 1;
        
        IF v_diferencia = 0 THEN
            SET v_msg = CONCAT('Corte cerrado para el ', p_fecha, '.');
        ELSEIF v_diferencia < 0 THEN
            SET v_msg = CONCAT('Corte cerrado con un FALTANTE de $', ABS(v_diferencia), '.');
        ELSE
            SET v_msg = CONCAT('Corte cerrado con un SOBRANTE de $', v_diferencia, '.');
        END IF;
        
        SET p_mensaje = v_msg;
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_corte_resumen` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_corte_resumen`(
    IN p_fecha DATE
)
BEGIN

    SELECT
        COUNT(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                   THEN 1 END)                                          AS num_ventas,
        COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                          THEN total END), 0)                           AS total_vendido,
        COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                          THEN total_piezas END), 0)                    AS total_piezas,
        COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                           AND metodo_pago = 'efectivo' COLLATE utf8mb4_0900_ai_ci
                          THEN total END), 0)                           AS efectivo,
        COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                           AND metodo_pago = 'tarjeta' COLLATE utf8mb4_0900_ai_ci
                          THEN total END), 0)                           AS tarjeta,
        COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                           AND metodo_pago = 'transferencia' COLLATE utf8mb4_0900_ai_ci
                          THEN total END), 0)                           AS transferencia,
        COALESCE(SUM(CASE WHEN estado = 'completada' COLLATE utf8mb4_0900_ai_ci
                           AND metodo_pago NOT IN (
                               'efectivo' COLLATE utf8mb4_0900_ai_ci,
                               'tarjeta'  COLLATE utf8mb4_0900_ai_ci,
                               'transferencia' COLLATE utf8mb4_0900_ai_ci)
                          THEN total END), 0)                           AS otro,
        COUNT(CASE WHEN estado = 'cancelada' COLLATE utf8mb4_0900_ai_ci
                   THEN 1 END)                                          AS cancelaciones
    FROM vw_corte_ventas_dia
    WHERE fecha = p_fecha;

    SELECT
        origen,
        folio,
        hora,
        ROUND(total, 2)           AS total,
        metodo_pago,
        estado,
        vendedor,
        ROUND(total_piezas, 0)    AS total_piezas
    FROM vw_corte_ventas_dia
    WHERE fecha = p_fecha
    ORDER BY hora ASC;

    SELECT
        p.nombre                        AS producto,
        ROUND(SUM(dv.cantidad), 0)      AS piezas_vendidas,
        ROUND(SUM(dv.subtotal), 2)      AS total_generado
    FROM ventas v
    JOIN detalle_ventas dv ON dv.id_venta   = v.id_venta
    JOIN productos      p  ON p.id_producto = dv.id_producto
    WHERE DATE(v.fecha_venta) = p_fecha
      AND v.estado = 'completada'
    GROUP BY p.id_producto, p.nombre
    ORDER BY piezas_vendidas DESC
    LIMIT 5;

    SELECT
        cd.id_corte,
        cd.estado,
        cd.total_ventas,
        cd.total_tickets,
        cd.total_piezas,
        cd.efectivo,
        cd.tarjeta,
        cd.transferencia,
        cd.cancelaciones,
        cd.cerrado_en,
        u.nombre_completo   AS cerrado_por_nombre
    FROM cortes_diarios cd
    LEFT JOIN usuarios u ON u.id_usuario = cd.cerrado_por
    WHERE cd.fecha_corte = p_fecha
    LIMIT 1;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_materia_prima` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_crear_materia_prima`(
    IN  p_uuid         VARCHAR(36)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_nombre       VARCHAR(120)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_categoria    VARCHAR(60)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_unidad_base  VARCHAR(20)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_stock_minimo DECIMAL(12,4),
    IN  p_estatus      VARCHAR(10)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_creado_por   INT
)
BEGIN
    
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de la materia prima es obligatorio.';
    END IF;

    
    IF p_unidad_base IS NULL OR TRIM(p_unidad_base) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La unidad base es obligatoria.';
    END IF;

    
    IF EXISTS (
        SELECT 1 FROM materias_primas
        WHERE  LOWER(nombre) = LOWER(TRIM(p_nombre))
        LIMIT  1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe una materia prima con ese nombre.';
    END IF;

    
    INSERT INTO materias_primas (
        uuid_materia,   nombre,        categoria,
        unidad_base,    stock_actual,  stock_minimo,
        estatus,        creado_en,     actualizado_en,
        creado_por
    ) VALUES (
        p_uuid,
        TRIM(p_nombre),
        NULLIF(TRIM(p_categoria), ''),
        TRIM(p_unidad_base),
        0,
        IFNULL(p_stock_minimo, 0),
        IF(p_estatus IN ('activo', 'inactivo'), p_estatus, 'activo'),
        NOW(),
        NOW(),
        p_creado_por
    );

    
    INSERT INTO logs_sistema (
        tipo,         nivel,  id_usuario,  modulo,
        accion,       descripcion,         creado_en
    ) VALUES (
        'ajuste_inv', 'INFO', p_creado_por, 'materias_primas',
        'CREAR',
        CONCAT('Materia prima creada: ', TRIM(p_nombre)),
        NOW()
    );

    
    SELECT LAST_INSERT_ID() AS id_materia;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_orden_produccion` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_crear_orden_produccion`(
  IN  p_id_receta      INT,
  IN  p_cantidad_lotes DECIMAL(10,2),
  IN  p_operario_id    INT,
  IN  p_observaciones  TEXT,
  IN  p_creado_por     INT,
  OUT p_id_produccion  INT,
  OUT p_folio          VARCHAR(20),
  OUT p_ok             TINYINT(1),
  OUT p_mensaje        VARCHAR(500)
)
proc: BEGIN
  DECLARE v_id_producto    INT           DEFAULT NULL;
  DECLARE v_rendimiento    DECIMAL(10,2) DEFAULT NULL;
  DECLARE v_estatus_receta VARCHAR(10)   DEFAULT NULL;
  DECLARE v_piezas_esp     DECIMAL(10,2) DEFAULT 0;
  DECLARE v_max_id         INT           DEFAULT 0;
  DECLARE v_folio_gen      VARCHAR(20);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 @v_sqlerr = MESSAGE_TEXT;
    ROLLBACK;
    SET p_ok = 0; SET p_id_produccion = NULL; SET p_folio = NULL;
    SET p_mensaje = CONCAT('Error interno: ', COALESCE(@v_sqlerr, 'desconocido'));
  END;

  SET p_ok = 0; SET p_id_produccion = NULL; SET p_folio = NULL; SET p_mensaje = '';

  
  IF COALESCE(p_cantidad_lotes, 0) <= 0 THEN
    SET p_mensaje = 'La cantidad de lotes debe ser mayor a cero.';
    LEAVE proc;
  END IF;

  
  SELECT id_producto, rendimiento, estatus
    INTO v_id_producto, v_rendimiento, v_estatus_receta
    FROM recetas
   WHERE id_receta = p_id_receta
   LIMIT 1;

  IF v_estatus_receta IS NULL THEN
    SET p_mensaje = CONCAT('No existe la receta con id = ', p_id_receta, '.');
    LEAVE proc;
  END IF;
  IF v_estatus_receta != 'activo' THEN
    SET p_mensaje = 'La receta seleccionada no está activa.';
    LEAVE proc;
  END IF;
  IF v_id_producto IS NULL THEN
    SET p_mensaje = 'La receta no tiene un producto asociado. Configúrala antes de producir.';
    LEAVE proc;
  END IF;

  
  IF p_operario_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1
        FROM usuarios u
        JOIN roles r ON r.id_rol = u.id_rol
       WHERE u.id_usuario = p_operario_id
         AND u.estatus    = 'activo'
         AND r.clave_rol  IN ('panadero', 'admin')
    ) THEN
      SET p_mensaje = 'El operario no existe, no está activo o no tiene rol de panadero/admin.';
      LEAVE proc;
    END IF;
  END IF;

  
  SET v_piezas_esp = p_cantidad_lotes * v_rendimiento;

  
  SELECT COALESCE(MAX(id_produccion), 0) INTO v_max_id FROM produccion;
  SET v_folio_gen = CONCAT('L-', LPAD(v_max_id + 1, 4, '0'));

  
  WHILE EXISTS (SELECT 1 FROM produccion WHERE folio_lote = v_folio_gen) DO
    SET v_max_id    = v_max_id + 1;
    SET v_folio_gen = CONCAT('L-', LPAD(v_max_id + 1, 4, '0'));
  END WHILE;

  START TRANSACTION;

  INSERT INTO produccion (
    folio_lote,    id_producto,   id_receta,
    cantidad_lotes, piezas_esperadas, piezas_producidas,
    estado,         fecha_inicio,     fecha_fin_estimado,
    fecha_fin_real, operario_id,      observaciones,
    creado_en,      creado_por
  ) VALUES (
    v_folio_gen,   v_id_producto,  p_id_receta,
    p_cantidad_lotes, v_piezas_esp, NULL,
    'pendiente',    NULL,           NULL,
    NULL,           p_operario_id,  p_observaciones,
    NOW(),          p_creado_por
  );

  SET p_id_produccion = LAST_INSERT_ID();

  INSERT INTO logs_sistema (
    tipo, nivel, id_usuario, modulo, accion, descripcion,
    referencia_id, referencia_tipo, creado_en
  ) VALUES (
    'produccion', 'INFO', p_creado_por, 'Produccion', 'crear_orden',
    CONCAT('Orden ', v_folio_gen, ' creada. Receta id=', p_id_receta,
           ', Lotes=', p_cantidad_lotes, ', Piezas esperadas=', v_piezas_esp),
    p_id_produccion, 'produccion', NOW()
  );

  COMMIT;

  SET p_folio   = v_folio_gen;
  SET p_ok      = 1;
  SET p_mensaje = CONCAT('Orden ', v_folio_gen, ' creada exitosamente. ',
                         'Piezas esperadas: ', v_piezas_esp, '.');
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_crear_pedido`(
    IN  p_id_cliente     INT,
    IN  p_fecha_recogida DATETIME,
    IN  p_notas          TEXT,
    IN  p_productos_json JSON,
    OUT p_id_pedido      INT,
    OUT p_folio          VARCHAR(15),
    OUT p_error          VARCHAR(255)
)
BEGIN
    DECLARE v_total   DECIMAL(10,2) DEFAULT 0;
    DECLARE v_i       INT DEFAULT 0;
    DECLARE v_n       INT;
    DECLARE v_id_prod INT;
    DECLARE v_qty     DECIMAL(10,2);
    DECLARE v_precio  DECIMAL(10,2);
    DECLARE v_sub     DECIMAL(12,2);
    DECLARE v_uuid    VARCHAR(36);
    DECLARE v_rol     VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
        SET p_id_pedido = NULL;
        SET p_folio     = NULL;
    END;

    SET p_error = NULL;

    
    SELECT CONVERT(r.clave_rol USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      INTO v_rol
      FROM usuarios u
      JOIN roles r ON r.id_rol = u.id_rol
     WHERE u.id_usuario = p_id_cliente
       AND CONVERT(u.estatus USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = 'activo'
     LIMIT 1;

    IF v_rol IS NULL OR v_rol != 'cliente' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El cliente no existe o no está activo.';
    END IF;

    
    SET v_n = JSON_LENGTH(p_productos_json);
    IF v_n IS NULL OR v_n = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El pedido debe tener al menos un producto.';
    END IF;

    
    WHILE v_i < v_n DO
        SET v_qty   = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].qty')));
        SET v_precio= JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].precio')));
        SET v_total = v_total + (v_qty * v_precio);
        SET v_i     = v_i + 1;
    END WHILE;

    START TRANSACTION;

        CALL sp_siguiente_folio_pedido(p_folio);
        SET v_uuid = UUID();

        INSERT INTO pedidos (
            uuid_pedido, folio, id_cliente, estado,
            fecha_recogida, notas_cliente, total_estimado,
            creado_en, actualizado_en
        ) VALUES (
            v_uuid, p_folio, p_id_cliente, 'pendiente',
            p_fecha_recogida, p_notas, ROUND(v_total, 2),
            NOW(), NOW()
        );

        SET p_id_pedido = LAST_INSERT_ID();

        SET v_i = 0;
        WHILE v_i < v_n DO
            SET v_id_prod = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].id')));
            SET v_qty     = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].qty')));
            SET v_precio  = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].precio')));
            SET v_sub     = ROUND(v_qty * v_precio, 2);

            IF NOT EXISTS (
                SELECT 1 FROM productos
                 WHERE id_producto = v_id_prod
                   AND CONVERT(estatus USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = 'activo'
            ) THEN
                SIGNAL SQLSTATE '45000'
                    SET MESSAGE_TEXT = 'Uno o más productos no están disponibles.';
            END IF;

            INSERT INTO detalle_pedidos
                (id_pedido, id_producto, cantidad, precio_unitario, subtotal)
            VALUES
                (p_id_pedido, v_id_prod, v_qty, v_precio, v_sub);

            SET v_i = v_i + 1;
        END WHILE;

        INSERT INTO historial_pedidos
            (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
        VALUES
            (p_id_pedido, 'nuevo', 'pendiente', 'Pedido creado por el cliente', p_id_cliente, NOW());

    COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_pedido_caja` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_crear_pedido_caja`(
  IN  p_cliente   INT,
  IN  p_fecha     DATETIME,
  IN  p_cajas     JSON,       
  OUT p_id_pedido INT,
  OUT p_folio     VARCHAR(20),
  OUT p_error     VARCHAR(255)
)
sp_main: BEGIN
  DECLARE v_n_cajas    INT;
  DECLARE v_i_caja     INT DEFAULT 0;
  DECLARE v_n_panes    INT;
  DECLARE v_i_pan      INT;
  DECLARE v_id_tamanio INT;
  DECLARE v_tipo       VARCHAR(10);
  DECLARE v_capacidad  TINYINT;
  DECLARE v_total_pzas INT;
  DECLARE v_id_prod    INT;
  DECLARE v_cantidad   INT;
  DECLARE v_precio     DECIMAL(10,2);
  DECLARE v_subtotal   DECIMAL(12,2);
  DECLARE v_total_ped  DECIMAL(12,2) DEFAULT 0;
  DECLARE v_folio      VARCHAR(15);
  DECLARE v_next_id    INT;
  DECLARE v_caja_path  VARCHAR(20);
  DECLARE v_pan_path   VARCHAR(40);

  SET p_id_pedido = NULL;
  SET p_folio     = NULL;
  SET p_error     = NULL;

  
  IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_cliente) THEN
    SET p_error = 'Cliente no encontrado.';
    LEAVE sp_main;
  END IF;

  SET v_n_cajas = JSON_LENGTH(p_cajas);

  IF v_n_cajas = 0 THEN
    SET p_error = 'El pedido debe tener al menos una caja.';
    LEAVE sp_main;
  END IF;

  
  WHILE v_i_caja < v_n_cajas DO
    SET v_caja_path  = CONCAT('$[', v_i_caja, ']');
    SET v_id_tamanio = JSON_UNQUOTE(JSON_EXTRACT(p_cajas, CONCAT(v_caja_path, '.id_tamanio')));
    SET v_tipo       = JSON_UNQUOTE(JSON_EXTRACT(p_cajas, CONCAT(v_caja_path, '.tipo')));

    
    SELECT capacidad INTO v_capacidad
    FROM tamanios_charola
    WHERE id_tamanio = v_id_tamanio AND estatus = 'activo';

    IF v_capacidad IS NULL THEN
      SET p_error = CONCAT('Caja ', v_i_caja + 1, ': tamaño de charola inválido.');
      LEAVE sp_main;
    END IF;

    
    IF v_capacidad = 4 AND v_tipo != 'simple' THEN
      SET p_error = CONCAT('Caja ', v_i_caja + 1, ': la charola chica solo puede ser simple.');
      LEAVE sp_main;
    END IF;
    IF v_tipo = 'triple' AND v_capacidad != 12 THEN
      SET p_error = CONCAT('Caja ', v_i_caja + 1, ': el tipo triple solo aplica para charola grande.');
      LEAVE sp_main;
    END IF;

    
    SET v_n_panes    = JSON_LENGTH(JSON_EXTRACT(p_cajas, CONCAT(v_caja_path, '.panes')));
    SET v_i_pan      = 0;
    SET v_total_pzas = 0;

    WHILE v_i_pan < v_n_panes DO
      SET v_pan_path   = CONCAT(v_caja_path, '.panes[', v_i_pan, ']');
      SET v_cantidad   = JSON_UNQUOTE(JSON_EXTRACT(p_cajas, CONCAT(v_pan_path, '.cantidad')));
      SET v_total_pzas = v_total_pzas + v_cantidad;
      SET v_i_pan      = v_i_pan + 1;
    END WHILE;

    IF v_total_pzas != v_capacidad THEN
      SET p_error = CONCAT(
        'Caja ', v_i_caja + 1, ': las piezas seleccionadas (', v_total_pzas,
        ') no coinciden con la capacidad de la charola (', v_capacidad, ').'
      );
      LEAVE sp_main;
    END IF;

    
    SET v_i_pan = 0;
    WHILE v_i_pan < v_n_panes DO
      SET v_pan_path = CONCAT(v_caja_path, '.panes[', v_i_pan, ']');
      SET v_precio   = JSON_UNQUOTE(JSON_EXTRACT(p_cajas, CONCAT(v_pan_path, '.precio')));
      SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_cajas, CONCAT(v_pan_path, '.cantidad')));
      SET v_total_ped = v_total_ped + (v_precio * v_cantidad);
      SET v_i_pan     = v_i_pan + 1;
    END WHILE;

    SET v_i_caja = v_i_caja + 1;
  END WHILE;

  
  SELECT IFNULL(MAX(id_pedido), 0) + 1 INTO v_next_id FROM pedidos;
  SET v_folio = CONCAT('PED-', LPAD(v_next_id, 4, '0'));

  INSERT INTO pedidos
    (uuid_pedido, folio, id_cliente, id_tamanio, tipo,
     fecha_recogida, total_estimado, estado, creado_en, actualizado_en)
  VALUES
    (UUID(), v_folio, p_cliente,
     NULL,    
     'mixta', 
     p_fecha, v_total_ped, 'pendiente', NOW(), NOW());

  SET p_id_pedido = LAST_INSERT_ID();
  SET p_folio     = v_folio;

  
  SET v_i_caja = 0;
  WHILE v_i_caja < v_n_cajas DO
    SET v_caja_path  = CONCAT('$[', v_i_caja, ']');
    SET v_id_tamanio = JSON_UNQUOTE(JSON_EXTRACT(p_cajas, CONCAT(v_caja_path, '.id_tamanio')));
    SET v_tipo       = JSON_UNQUOTE(JSON_EXTRACT(p_cajas, CONCAT(v_caja_path, '.tipo')));
    SET v_n_panes    = JSON_LENGTH(JSON_EXTRACT(p_cajas, CONCAT(v_caja_path, '.panes')));
    SET v_i_pan      = 0;

    WHILE v_i_pan < v_n_panes DO
      SET v_pan_path = CONCAT(v_caja_path, '.panes[', v_i_pan, ']');
      SET v_id_prod  = JSON_UNQUOTE(JSON_EXTRACT(p_cajas, CONCAT(v_pan_path, '.id_producto')));
      SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_cajas, CONCAT(v_pan_path, '.cantidad')));
      SET v_precio   = JSON_UNQUOTE(JSON_EXTRACT(p_cajas, CONCAT(v_pan_path, '.precio')));
      SET v_subtotal = v_precio * v_cantidad;

      
      
      INSERT INTO detalle_pedidos
        (id_pedido, id_producto, cantidad, precio_unitario, subtotal)
      VALUES
        (p_id_pedido, v_id_prod, v_cantidad, v_precio, v_subtotal);

      SET v_i_pan = v_i_pan + 1;
    END WHILE;

    SET v_i_caja = v_i_caja + 1;
  END WHILE;

  
  INSERT INTO historial_pedidos
    (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
  VALUES
    (p_id_pedido, 'nuevo', 'pendiente',
     CONCAT('Pedido creado con ', v_n_cajas, ' caja(s).'),
     p_cliente, NOW());

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_pedido_compra` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_crear_pedido_compra`(
    IN  p_folio          VARCHAR(20)  CHARACTER SET utf8mb4,
    IN  p_folio_factura  VARCHAR(60)  CHARACTER SET utf8mb4,
    IN  p_id_proveedor   INT,
    IN  p_fecha_compra   DATE,
    IN  p_observaciones  TEXT         CHARACTER SET utf8mb4,
    IN  p_creado_por     INT,
    OUT p_id_compra      INT
)
BEGIN
    
    IF NOT EXISTS (
        SELECT 1 FROM proveedores
        WHERE id_proveedor = p_id_proveedor AND estatus = 'activo'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El proveedor no existe o está inactivo.';
    END IF;

    
    IF EXISTS (SELECT 1 FROM compras WHERE folio = p_folio) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El folio de compra ya existe.';
    END IF;

    INSERT INTO compras (
        folio, folio_factura, id_proveedor, fecha_compra,
        total, estatus, observaciones, creado_en, creado_por
    ) VALUES (
        p_folio, NULLIF(p_folio_factura,''), p_id_proveedor, p_fecha_compra,
        0, 'ordenado', NULLIF(p_observaciones,''), NOW(), p_creado_por
    );

    SET p_id_compra = LAST_INSERT_ID();
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_producto` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_crear_producto`(
    IN  p_uuid        VARCHAR(36)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_nombre      VARCHAR(120)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_descripcion TEXT           CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_precio_venta DECIMAL(10,2),
    IN  p_imagen_url  VARCHAR(255)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_creado_por  INT
)
BEGIN
    DECLARE v_id INT;

    
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre del producto es obligatorio.';
    END IF;

    
    IF p_precio_venta IS NULL OR p_precio_venta <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El precio de venta debe ser mayor a 0.';
    END IF;

    
    IF EXISTS (
        SELECT 1 FROM productos
        WHERE  LOWER(nombre) = LOWER(TRIM(p_nombre))
        LIMIT  1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe un producto con ese nombre.';
    END IF;

    
    INSERT INTO productos (
        uuid_producto,  nombre,         descripcion,
        imagen_url,     precio_venta,   estatus,
        creado_en,      actualizado_en, creado_por
    ) VALUES (
        p_uuid,
        TRIM(p_nombre),
        NULLIF(TRIM(IFNULL(p_descripcion, '')), ''),
        p_imagen_url,
        p_precio_venta,
        'activo',
        NOW(),
        NOW(),
        p_creado_por
    );

    SET v_id = LAST_INSERT_ID();

    
    INSERT INTO inventario_pt (
        id_producto, stock_actual, stock_minimo, ultima_actualizacion
    ) VALUES (
        v_id, 0, 0, NOW()
    );

    
    INSERT INTO logs_sistema (
        tipo,    nivel,  id_usuario,  modulo,
        accion,  descripcion,         creado_en
    ) VALUES (
        'venta', 'INFO', p_creado_por, 'productos',
        'CREAR',
        CONCAT('Producto creado: ', TRIM(p_nombre)),
        NOW()
    );

    SELECT v_id AS id_producto;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_proveedor` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_crear_proveedor`(
    IN  p_uuid        VARCHAR(36)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_nombre      VARCHAR(150)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_rfc         VARCHAR(13)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_contacto    VARCHAR(120)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_telefono    VARCHAR(20)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_email       VARCHAR(150)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_direccion   TEXT          CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_creado_por  INT
)
BEGIN
    
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre del proveedor es obligatorio.';
    END IF;

    
    IF p_rfc IS NOT NULL AND TRIM(p_rfc) <> '' AND
       EXISTS (SELECT 1 FROM proveedores WHERE rfc = TRIM(p_rfc)) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe un proveedor registrado con ese RFC.';
    END IF;

    
    INSERT INTO proveedores (
        uuid_proveedor, nombre,        rfc,
        contacto,       telefono,      email,
        direccion,      estatus,       creado_en,
        actualizado_en, creado_por
    ) VALUES (
        p_uuid,
        TRIM(p_nombre),
        NULLIF(TRIM(p_rfc),       ''),
        NULLIF(TRIM(p_contacto),  ''),
        NULLIF(TRIM(p_telefono),  ''),
        NULLIF(TRIM(p_email),     ''),
        NULLIF(TRIM(p_direccion), ''),
        'activo',
        NOW(),
        NOW(),
        p_creado_por
    );

    
    INSERT INTO logs_sistema (
        tipo,    nivel,  id_usuario,   modulo,
        accion,  descripcion,          creado_en
    ) VALUES (
        'compra', 'INFO', p_creado_por, 'proveedores',
        'CREAR',
        CONCAT('Proveedor creado: ', TRIM(p_nombre)),
        NOW()
    );

    
    SELECT LAST_INSERT_ID() AS id_proveedor;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_receta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_receta`(
    IN  p_uuid               VARCHAR(36),
    IN  p_id_producto        INT,
    IN  p_nombre             VARCHAR(120),
    IN  p_descripcion        TEXT,
    IN  p_rendimiento        DECIMAL(10,2),
    IN  p_unidad_rendimiento VARCHAR(20),
    IN  p_precio_venta       DECIMAL(10,2),
    IN  p_creado_por         INT,
    OUT p_id_receta          INT
)
BEGIN
    -- ── Validaciones ──────────────────────────────────────────
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de la receta es obligatorio.';
    END IF;

    IF p_rendimiento IS NULL OR p_rendimiento <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El rendimiento debe ser mayor a 0.';
    END IF;

    IF p_id_producto IS NOT NULL AND p_id_producto <> 0 AND
       NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = p_id_producto) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El producto seleccionado no existe.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM recetas
        WHERE  CONVERT(nombre USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
             = CONVERT(TRIM(p_nombre) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
        LIMIT 1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe una receta con ese nombre.';
    END IF;

    -- ── Insertar encabezado ───────────────────────────────────
    INSERT INTO recetas (
        uuid_receta, id_producto, nombre, descripcion,
        rendimiento, unidad_rendimiento, precio_venta,
        estatus, creado_en, actualizado_en, creado_por
    ) VALUES (
        p_uuid,
        NULLIF(p_id_producto, 0),
        TRIM(p_nombre),
        NULLIF(TRIM(IFNULL(p_descripcion, '')), ''),
        p_rendimiento,
        p_unidad_rendimiento,
        NULLIF(p_precio_venta, 0),
        'activo',
        NOW(), NOW(),
        p_creado_por
    );

    SET p_id_receta = LAST_INSERT_ID();

    -- ── Insertar detalles desde la tabla temporal ─────────────
    INSERT INTO detalle_recetas
        (id_receta, id_materia, id_unidad_presentacion,
         cantidad_presentacion, cantidad_requerida, orden)
    SELECT
        p_id_receta,
        id_materia,
        id_unidad_presentacion,
        cantidad_presentacion,
        cantidad_requerida,
        orden
    FROM tmp_insumos_receta;

    -- ── Auditoría ─────────────────────────────────────────────
    INSERT INTO logs_sistema (
        tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en
    ) VALUES (
        'produccion', 'INFO', p_creado_por, 'recetas',
        'CREAR',
        CONCAT('Receta creada: ', TRIM(p_nombre)),
        NOW()
    );

    -- ── Limpiar tabla temporal ────────────────────────────────
    DROP TEMPORARY TABLE IF EXISTS tmp_insumos_receta;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_unidad_compra` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_crear_unidad_compra`(
    IN  p_id_materia    INT,
    IN  p_nombre        VARCHAR(80),
    IN  p_simbolo       VARCHAR(20),
    IN  p_factor_a_base DECIMAL(14,6),
    IN  p_uso           VARCHAR(10),
    OUT p_id_unidad     INT
)
BEGIN
    IF p_factor_a_base <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El factor debe ser mayor a 0.';
    END IF;
    IF p_uso NOT IN ('compra','ambos') THEN
        SET p_uso = 'compra';
    END IF;

    
    IF EXISTS (
        SELECT 1 FROM unidades_presentacion
        WHERE id_materia = p_id_materia
          AND simbolo COLLATE utf8mb4_0900_ai_ci = p_simbolo COLLATE utf8mb4_0900_ai_ci
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe una unidad con ese símbolo para esta materia prima. Usa un símbolo diferente (ej. caja360, saco50).';
    END IF;

    INSERT INTO unidades_presentacion (id_materia, nombre, simbolo, factor_a_base, uso, activo, creado_en)
    VALUES (p_id_materia, p_nombre, p_simbolo, p_factor_a_base, p_uso, TRUE, NOW());

    SET p_id_unidad = LAST_INSERT_ID();
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_usuario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_usuario`(
    IN  p_uuid            VARCHAR(36)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_nombre_completo VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_username        VARCHAR(60)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_password_hash   VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_id_rol          SMALLINT,
    IN  p_estatus         VARCHAR(10)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_creado_por      INT
)
    SQL SECURITY INVOKER
BEGIN
    -- Verificar que el username no esté duplicado
    IF EXISTS (SELECT 1 FROM usuarios WHERE username = p_username) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de usuario ya esta en uso.';
    END IF;

    -- Verificar que el rol exista
    IF NOT EXISTS (SELECT 1 FROM roles WHERE id_rol = p_id_rol) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El rol seleccionado no es valido.';
    END IF;

    INSERT INTO usuarios (
        uuid_usuario,
        nombre_completo,
        username,
        password_hash,
        id_rol,
        estatus,
        intentos_fallidos,
        cambio_pwd_req,
        creado_en,
        actualizado_en,
        creado_por
    ) VALUES (
        p_uuid,
        p_nombre_completo,
        p_username,
        p_password_hash,
        p_id_rol,
        p_estatus,
        0,
        0,
        NOW(),
        NOW(),
        p_creado_por
    );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_venta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_crear_venta`(
    IN  p_vendedor_id     INT,
    IN  p_metodo_pago     VARCHAR(20),
    IN  p_monto_recibido  DECIMAL(12,2),   
    IN  p_requiere_ticket TINYINT(1),
    IN  p_items           JSON,
    
    OUT p_id_venta        INT,
    OUT p_folio           VARCHAR(20),
    OUT p_cambio          DECIMAL(10,2),
    OUT p_error           VARCHAR(255)
)
sp_main: BEGIN
    DECLARE v_n          INT;
    DECLARE v_i          INT DEFAULT 0;
    DECLARE v_id_prod    INT;
    DECLARE v_cantidad   DECIMAL(10,2);
    DECLARE v_precio     DECIMAL(10,2);
    DECLARE v_desc_pct   DECIMAL(5,2);
    DECLARE v_subtotal   DECIMAL(12,2);
    DECLARE v_total      DECIMAL(12,2) DEFAULT 0;
    DECLARE v_stock      DECIMAL(12,2);
    DECLARE v_nombre_prod VARCHAR(120);
    DECLARE v_next_seq   INT;
    DECLARE v_folio      VARCHAR(20);
    DECLARE v_cambio     DECIMAL(10,2) DEFAULT 0;
    DECLARE v_ticket_json JSON;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
        SET p_id_venta = NULL;
        SET p_folio    = NULL;
        SET p_cambio   = NULL;
    END;

    SET p_error    = NULL;
    SET p_id_venta = NULL;
    SET p_folio    = NULL;
    SET p_cambio   = 0;

    
    IF p_metodo_pago NOT IN ('efectivo','tarjeta','transferencia','otro') THEN
        SET p_error = 'Método de pago inválido.';
        LEAVE sp_main;
    END IF;

    
    SET v_n = JSON_LENGTH(p_items);
    IF v_n IS NULL OR v_n = 0 THEN
        SET p_error = 'La venta debe incluir al menos un producto.';
        LEAVE sp_main;
    END IF;

    
    SET v_i = 0;
    WHILE v_i < v_n DO
        SET v_id_prod  = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[',v_i,'].id_producto')))  AS UNSIGNED);
        SET v_cantidad = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[',v_i,'].cantidad')))       AS DECIMAL(10,2));

        SELECT nombre INTO v_nombre_prod
        FROM   productos
        WHERE  id_producto = v_id_prod AND estatus = 'activo';

        IF v_nombre_prod IS NULL THEN
            SET p_error = CONCAT('Producto ID ', v_id_prod, ' no existe o está inactivo.');
            LEAVE sp_main;
        END IF;

        SELECT COALESCE(stock_actual, 0) INTO v_stock
        FROM   inventario_pt
        WHERE  id_producto = v_id_prod;

        IF v_stock < v_cantidad THEN
            SET p_error = CONCAT('Stock insuficiente para "', v_nombre_prod,
                                 '". Disponible: ', v_stock, ', solicitado: ', v_cantidad);
            LEAVE sp_main;
        END IF;

        SET v_i = v_i + 1;
    END WHILE;

    
    SELECT COUNT(*) + 1 INTO v_next_seq
    FROM   ventas
    WHERE  DATE(fecha_venta) = CURDATE();

    SET v_folio = CONCAT('VTA-', DATE_FORMAT(NOW(),'%Y%m%d'), '-', LPAD(v_next_seq, 3, '0'));

    START TRANSACTION;

    
    INSERT INTO ventas (folio_venta, fecha_venta, total, metodo_pago, cambio,
                        requiere_ticket, estado, vendedor_id, creado_en)
    VALUES (v_folio, NOW(), 0, p_metodo_pago, 0,
            p_requiere_ticket, 'abierta', p_vendedor_id, NOW());

    SET p_id_venta = LAST_INSERT_ID();

    
    SET v_i     = 0;
    SET v_total = 0;

    WHILE v_i < v_n DO
        SET v_id_prod  = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[',v_i,'].id_producto')))  AS UNSIGNED);
        SET v_cantidad = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[',v_i,'].cantidad')))       AS DECIMAL(10,2));
        SET v_precio   = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[',v_i,'].precio_unitario'))) AS DECIMAL(10,2));
        SET v_desc_pct = CAST(COALESCE(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[',v_i,'].descuento_pct'))), 0) AS DECIMAL(5,2));
        SET v_subtotal = ROUND(v_cantidad * v_precio * (1 - v_desc_pct / 100), 2);
        SET v_total    = v_total + v_subtotal;

        INSERT INTO detalle_ventas (id_venta, id_producto, cantidad,
                                    precio_unitario, descuento_pct, subtotal)
        VALUES (p_id_venta, v_id_prod, v_cantidad, v_precio, v_desc_pct, v_subtotal);

        
        UPDATE inventario_pt
        SET    stock_actual = stock_actual - v_cantidad
        WHERE  id_producto  = v_id_prod;

        SET v_i = v_i + 1;
    END WHILE;

    
    IF p_metodo_pago = 'efectivo' THEN
        IF p_monto_recibido IS NULL OR p_monto_recibido < v_total THEN
            ROLLBACK;
            SET p_error    = CONCAT('Monto recibido (', COALESCE(p_monto_recibido,'—'),
                                    ') insuficiente. Total: ', v_total);
            SET p_id_venta = NULL;
            SET p_folio    = NULL;
            LEAVE sp_main;
        END IF;
        SET v_cambio = p_monto_recibido - v_total;
    END IF;

    
    UPDATE ventas
    SET    total  = v_total,
           cambio = v_cambio,
           estado = 'completada'
    WHERE  id_venta = p_id_venta;

    
    IF p_requiere_ticket = 1 THEN
        SELECT JSON_OBJECT(
                    'folio',        v_folio,
                    'fecha',        DATE_FORMAT(NOW(), '%d/%m/%Y %H:%i'),
                    'metodo_pago',  p_metodo_pago,
                    'total',        v_total,
                    'cambio',       v_cambio,
                    'monto_recibido', p_monto_recibido,
                    'items', (
                        SELECT JSON_ARRAYAGG(
                                   JSON_OBJECT(
                                       'nombre',      pr.nombre,
                                       'cantidad',    dv.cantidad,
                                       'precio',      dv.precio_unitario,
                                       'descuento',   dv.descuento_pct,
                                       'subtotal',    dv.subtotal
                                   )
                               )
                        FROM detalle_ventas dv
                        JOIN productos      pr ON pr.id_producto = dv.id_producto
                        WHERE dv.id_venta = p_id_venta
                    )
               ) INTO v_ticket_json;

        INSERT INTO tickets (id_venta, contenido_json, impreso, generado_en)
        VALUES (p_id_venta, v_ticket_json, 0, NOW());
    END IF;

    
    INSERT INTO logs_sistema (tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en)
    VALUES ('venta', 'INFO', p_vendedor_id, 'ventas', 'crear_venta',
            CONCAT('Venta registrada: ', v_folio, ' | Total: $', v_total), NOW());

    COMMIT;

    SET p_folio  = v_folio;
    SET p_cambio = v_cambio;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_crear_venta_desde_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_crear_venta_desde_pedido`(
    IN p_id_pedido INT,
    IN p_vendedor_id INT,
    OUT p_id_venta INT
)
BEGIN
    DECLARE v_folio VARCHAR(20);
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_next_seq INT;
    
    -- Calcular total del pedido
    SELECT SUM(subtotal) INTO v_total
    FROM detalle_pedidos
    WHERE id_pedido = p_id_pedido;
    
    -- Generar folio
    SELECT COUNT(*) + 1 INTO v_next_seq
    FROM ventas
    WHERE DATE(fecha_venta) = CURDATE();
    
    SET v_folio = CONCAT('VTA-', DATE_FORMAT(NOW(),'%Y%m%d'), '-', LPAD(v_next_seq, 3, '0'));
    
    -- Insertar cabecera de venta
    INSERT INTO ventas (folio_venta, fecha_venta, total, metodo_pago, cambio,
                        requiere_ticket, estado, vendedor_id, creado_en)
    VALUES (v_folio, NOW(), v_total, 'transferencia', 0,
            1, 'completada', p_vendedor_id, NOW());
    
    SET p_id_venta = LAST_INSERT_ID();
    
    -- Insertar detalles de venta desde el pedido
    INSERT INTO detalle_ventas (id_venta, id_producto, cantidad, 
                                precio_unitario, descuento_pct, subtotal)
    SELECT p_id_venta, id_producto, cantidad, precio_unitario, 0, subtotal
    FROM detalle_pedidos
    WHERE id_pedido = p_id_pedido;
    
    -- Descontar inventario
    UPDATE inventario_pt i
    JOIN detalle_pedidos dp ON dp.id_producto = i.id_producto
    SET i.stock_actual = i.stock_actual - dp.cantidad
    WHERE dp.id_pedido = p_id_pedido;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_dash_mp_criticas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_dash_mp_criticas`()
BEGIN
    SELECT
        nombre,
        categoria,
        unidad_base,
        stock_actual,
        stock_minimo,
        pct_stock,
        nivel
    FROM vw_dash_mp_criticas
    ORDER BY pct_stock ASC
    LIMIT 20;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_dash_salidas_efectivo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_dash_salidas_efectivo`(IN p_periodo VARCHAR(10))
BEGIN
    DECLARE v_dias      INT;
    DECLARE v_desde     DATE;
    DECLARE v_desde_ant DATE;

    CASE p_periodo
        WHEN 'hoy'     THEN SET v_dias = 1;
        WHEN 'semanal' THEN SET v_dias = 7;
        WHEN 'mensual' THEN SET v_dias = 30;
        WHEN 'anual'   THEN SET v_dias = 365;
        ELSE                SET v_dias = 7;
    END CASE;

    IF p_periodo = 'hoy' THEN
        SET v_desde     = CURDATE();
        SET v_desde_ant = DATE_SUB(CURDATE(), INTERVAL 1 DAY);
    ELSE
        SET v_desde     = DATE_SUB(CURDATE(), INTERVAL v_dias DAY);
        SET v_desde_ant = DATE_SUB(CURDATE(), INTERVAL v_dias * 2 DAY);
    END IF;

    IF p_periodo = 'hoy' THEN
        SELECT
            COALESCE(SUM(CASE WHEN fecha_salida = v_desde     THEN monto END), 0) AS total_actual,
            COALESCE(SUM(CASE WHEN fecha_salida = v_desde_ant THEN monto END), 0) AS total_anterior,
            COALESCE(COUNT(CASE WHEN fecha_salida = v_desde     THEN 1 END), 0)   AS movimientos_actual,
            COALESCE(COUNT(CASE WHEN fecha_salida = v_desde_ant THEN 1 END), 0)   AS movimientos_anterior
        FROM salidas_efectivo
        WHERE estado = 'aprobada'
          AND fecha_salida >= v_desde_ant;
    ELSE
        SELECT
            COALESCE(SUM(CASE WHEN fecha_salida >= v_desde     THEN monto END), 0) AS total_actual,
            COALESCE(SUM(CASE WHEN fecha_salida >= v_desde_ant AND fecha_salida < v_desde THEN monto END), 0) AS total_anterior,
            COALESCE(COUNT(CASE WHEN fecha_salida >= v_desde     THEN 1 END), 0)   AS movimientos_actual,
            COALESCE(COUNT(CASE WHEN fecha_salida >= v_desde_ant AND fecha_salida < v_desde THEN 1 END), 0) AS movimientos_anterior
        FROM salidas_efectivo
        WHERE estado = 'aprobada'
          AND fecha_salida >= v_desde_ant;
    END IF;

    IF p_periodo = 'hoy' THEN
        SELECT categoria, COUNT(*) AS movimientos, SUM(monto) AS total_categoria
        FROM salidas_efectivo
        WHERE estado = 'aprobada' AND fecha_salida = v_desde
        GROUP BY categoria ORDER BY total_categoria DESC;
    ELSE
        SELECT categoria, COUNT(*) AS movimientos, SUM(monto) AS total_categoria
        FROM salidas_efectivo
        WHERE estado = 'aprobada' AND fecha_salida >= v_desde
        GROUP BY categoria ORDER BY total_categoria DESC;
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_dash_top_productos` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_dash_top_productos`()
BEGIN
    DECLARE v_desde DATE DEFAULT DATE_SUB(CURDATE(), INTERVAL 7 DAY);

    SELECT
        pr.nombre                     AS nombre_producto,
        SUM(pv.cantidad)              AS total_piezas,
        ROUND(SUM(pv.subtotal), 2)    AS total_ingresos
    FROM vw_dash_piezas_vendidas pv
    JOIN productos pr ON pr.id_producto = pv.id_producto
    WHERE pv.fecha   >= v_desde
      AND pr.estatus  = 'activo'
    GROUP BY pr.id_producto, pr.nombre
    ORDER BY total_piezas DESC
    LIMIT 5;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_dash_utilidad_por_producto` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_dash_utilidad_por_producto`()
BEGIN
    
    
    DROP TEMPORARY TABLE IF EXISTS _tmp_costo_receta;
    CREATE TEMPORARY TABLE _tmp_costo_receta AS
    SELECT
        dr.id_receta,
        ROUND(
            SUM(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0)),
            4
        ) AS costo_total_lote
    FROM detalle_recetas dr
    LEFT JOIN v_costo_promedio_materia cpm ON cpm.id_materia = dr.id_materia
    GROUP BY dr.id_receta;

    
    
    DROP TEMPORARY TABLE IF EXISTS _tmp_precio_venta_real;
    CREATE TEMPORARY TABLE _tmp_precio_venta_real AS
    SELECT
        dv.id_producto,
        ROUND(AVG(dv.precio_unitario), 2) AS precio_real
    FROM detalle_ventas dv
    INNER JOIN ventas v ON v.id_venta = dv.id_venta
    WHERE v.estado = 'completada'
      AND DATE(v.fecha_venta) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY dv.id_producto;

    SELECT
        p.id_producto,
        p.nombre                                                    AS nombre_producto,
        
        COALESCE(pvr.precio_real, p.precio_venta)                  AS precio_venta,
        r.id_receta,
        r.nombre                                                    AS nombre_receta,
        r.rendimiento,
        ROUND(
            COALESCE(tcr.costo_total_lote, 0) / r.rendimiento,
            4
        )                                                           AS costo_unitario,
        ROUND(
            COALESCE(pvr.precio_real, p.precio_venta)
                - (COALESCE(tcr.costo_total_lote, 0) / r.rendimiento),
            4
        )                                                           AS utilidad_unitaria,
        CASE
            WHEN COALESCE(pvr.precio_real, p.precio_venta) > 0 THEN
                ROUND(
                    (COALESCE(pvr.precio_real, p.precio_venta)
                        - COALESCE(tcr.costo_total_lote, 0) / r.rendimiento)
                    / COALESCE(pvr.precio_real, p.precio_venta) * 100,
                    2
                )
            ELSE 0
        END                                                         AS margen_pct
    FROM productos p
    INNER JOIN recetas r
            ON r.id_producto = p.id_producto
           AND r.estatus     = 'activo'
    LEFT JOIN _tmp_costo_receta        tcr ON tcr.id_receta   = r.id_receta
    LEFT JOIN _tmp_precio_venta_real   pvr ON pvr.id_producto = p.id_producto
    WHERE p.estatus = 'activo'
    ORDER BY utilidad_unitaria DESC;

    DROP TEMPORARY TABLE IF EXISTS _tmp_costo_receta;
    DROP TEMPORARY TABLE IF EXISTS _tmp_precio_venta_real;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_dash_ventas_totales` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_dash_ventas_totales`(IN p_periodo VARCHAR(10))
BEGIN
    DECLARE v_dias     INT;
    DECLARE v_desde    DATE;
    DECLARE v_desde_ant DATE;

    CASE p_periodo
        WHEN 'hoy'     THEN SET v_dias = 1;
        WHEN 'semanal' THEN SET v_dias = 7;
        WHEN 'mensual' THEN SET v_dias = 30;
        WHEN 'anual'   THEN SET v_dias = 365;
        ELSE                SET v_dias = 7;  
    END CASE;

    IF p_periodo = 'hoy' THEN
        SET v_desde     = CURDATE();
        SET v_desde_ant = DATE_SUB(CURDATE(), INTERVAL 1 DAY);
    ELSE
        SET v_desde     = DATE_SUB(CURDATE(), INTERVAL v_dias DAY);
        SET v_desde_ant = DATE_SUB(CURDATE(), INTERVAL v_dias * 2 DAY);
    END IF;

    IF p_periodo = 'hoy' THEN
        SELECT
            COALESCE(SUM(CASE WHEN fecha = v_desde     THEN monto END), 0) AS total_actual,
            COALESCE(SUM(CASE WHEN fecha = v_desde_ant THEN monto END), 0) AS total_anterior,
            COALESCE(COUNT(CASE WHEN fecha = v_desde     THEN 1 END), 0)   AS tickets_actual,
            COALESCE(COUNT(CASE WHEN fecha = v_desde_ant THEN 1 END), 0)   AS tickets_anterior
        FROM vw_dash_ventas_consolidadas
        WHERE fecha >= v_desde_ant;
    ELSE
        SELECT
            COALESCE(SUM(CASE WHEN fecha >= v_desde     THEN monto END), 0) AS total_actual,
            COALESCE(SUM(CASE WHEN fecha >= v_desde_ant AND fecha < v_desde THEN monto END), 0) AS total_anterior,
            COALESCE(COUNT(CASE WHEN fecha >= v_desde     THEN 1 END), 0)   AS tickets_actual,
            COALESCE(COUNT(CASE WHEN fecha >= v_desde_ant AND fecha < v_desde THEN 1 END), 0) AS tickets_anterior
        FROM vw_dash_ventas_consolidadas
        WHERE fecha >= v_desde_ant;
    END IF;

    IF p_periodo = 'hoy' THEN
        SELECT
            fecha,
            COALESCE(SUM(monto), 0) AS total_dia,
            COUNT(*)                 AS tickets
        FROM vw_dash_ventas_consolidadas
        WHERE fecha = v_desde
        GROUP BY fecha
        ORDER BY fecha ASC;
    ELSE
        SELECT
            fecha,
            COALESCE(SUM(monto), 0) AS total_dia,
            COUNT(*)                 AS tickets
        FROM vw_dash_ventas_consolidadas
        WHERE fecha >= v_desde
        GROUP BY fecha
        ORDER BY fecha ASC;
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_detalle_costo_producto` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_detalle_costo_producto`(
    IN p_id_receta INT
)
BEGIN
    SELECT
        mp.nombre                                   AS materia_nombre,
        mp.unidad_base,
        dr.cantidad_requerida,
        COALESCE(cpm.costo_base_promedio, 0)       AS costo_base_unitario,
        ROUND(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0), 4) AS subtotal_costo,
        
        ROUND(
            (dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0))
            / NULLIF(
                (SELECT SUM(dr2.cantidad_requerida * COALESCE(cpm2.costo_base_promedio, 0))
                 FROM detalle_recetas dr2
                 LEFT JOIN v_costo_promedio_materia cpm2 ON cpm2.id_materia = dr2.id_materia
                 WHERE dr2.id_receta = p_id_receta),
            0) * 100, 2
        )                                           AS pct_del_costo
    FROM detalle_recetas dr
    INNER JOIN materias_primas mp ON mp.id_materia = dr.id_materia
    LEFT JOIN v_costo_promedio_materia cpm ON cpm.id_materia = dr.id_materia
    WHERE dr.id_receta = p_id_receta
    ORDER BY subtotal_costo DESC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_detalle_orden_produccion` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_detalle_orden_produccion`(
  IN  p_id_produccion INT,
  OUT p_ok            TINYINT(1),
  OUT p_mensaje       VARCHAR(300)
)
sp_detalle_orden_produccion: BEGIN

  SET p_ok = 0;

  IF NOT EXISTS (SELECT 1 FROM produccion WHERE id_produccion = p_id_produccion) THEN
    SET p_mensaje = CONCAT('No existe la orden con id = ', p_id_produccion, '.');
    LEAVE sp_detalle_orden_produccion;
  END IF;

  SET p_ok = 1;
  SET p_mensaje = 'OK';

  
  SELECT
    p.id_produccion,
    p.folio_lote,
    r.id_receta,
    r.nombre             AS nombre_receta,
    r.rendimiento,
    r.unidad_rendimiento,
    pr.id_producto,
    pr.nombre            AS nombre_producto,
    p.cantidad_lotes,
    p.piezas_esperadas,
    p.piezas_producidas,
    p.estado,
    p.fecha_inicio,
    p.fecha_fin_estimado,
    p.fecha_fin_real,
    p.creado_en,
    p.observaciones,
    u_op.nombre_completo AS operario,
    u_cr.nombre_completo AS creado_por_nombre,
    (SELECT COUNT(*)
       FROM detalle_pedidos dp
       JOIN pedidos         ped ON ped.id_pedido = dp.id_pedido
      WHERE dp.id_producto = p.id_producto
        AND ped.estado IN ('pendiente','aprobado','en_produccion')
    )                    AS pedidos_pendientes
  FROM produccion    p
  JOIN recetas       r   ON r.id_receta    = p.id_receta
  JOIN productos     pr  ON pr.id_producto = p.id_producto
  LEFT JOIN usuarios u_op ON u_op.id_usuario = p.operario_id
  LEFT JOIN usuarios u_cr ON u_cr.id_usuario = p.creado_por
  WHERE p.id_produccion = p_id_produccion;

  
  SELECT
    dp.id_materia,
    mp.nombre            AS nombre_materia,
    mp.unidad_base,
    mp.categoria,
    dp.cantidad_requerida,
    dp.cantidad_descontada,
    mp.stock_actual      AS stock_post
  FROM detalle_produccion dp
  JOIN materias_primas    mp ON mp.id_materia = dp.id_materia
  WHERE dp.id_produccion = p_id_produccion
  ORDER BY mp.nombre;

  
  SELECT
    dr.id_materia,
    mp.nombre            AS nombre_materia,
    mp.unidad_base,
    mp.categoria,
    ROUND(p.cantidad_lotes * dr.cantidad_requerida, 4) AS cantidad_requerida,
    mp.stock_actual,
    CASE
      WHEN mp.stock_actual >= ROUND(p.cantidad_lotes * dr.cantidad_requerida, 4)
      THEN 1 ELSE 0
    END                  AS stock_suficiente
  FROM produccion      p
  JOIN detalle_recetas dr ON dr.id_receta  = p.id_receta
  JOIN materias_primas mp ON mp.id_materia = dr.id_materia
  WHERE p.id_produccion = p_id_produccion
  ORDER BY mp.nombre;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_detalle_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_detalle_pedido`(
  IN p_folio VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
)
BEGIN
 
SELECT v.id_pedido, v.folio, v.estado, v.fecha_recogida,
       v.total_estimado, v.motivo_rechazo, v.creado_en,
       v.id_cliente, v.cliente_nombre,
       u.telefono,
       v.atendido_por_nombre,
       v.tipo_caja, v.tamanio_nombre, v.capacidad
FROM v_pedidos_resumen v
JOIN usuarios u ON u.id_usuario = v.id_cliente
WHERE v.folio = p_folio
LIMIT 1;

  
  SELECT vc.tipo, vc.tamanio, vc.nombre_caja, vc.capacidad, vc.precio_venta
  FROM   v_caja_pedido vc
  JOIN   pedidos       p  ON p.id_pedido = vc.id_pedido
  WHERE  p.folio = p_folio
  LIMIT  1;

  
  SELECT vd.producto_nombre, vd.producto_descripcion,
         vd.cantidad, vd.precio_unitario, vd.subtotal
  FROM   v_detalle_pedido vd
  JOIN   pedidos          p ON p.id_pedido = vd.id_pedido
  WHERE  p.folio = p_folio
  ORDER  BY vd.producto_nombre;

  
  SELECT vh.estado_antes, vh.estado_despues, vh.nota,
         vh.creado_en, vh.usuario_nombre
  FROM   v_historial_pedido vh
  JOIN   pedidos            p ON p.id_pedido = vh.id_pedido
  WHERE  p.folio = p_folio
  ORDER  BY vh.creado_en ASC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_detalle_venta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_detalle_venta`(
    IN p_folio VARCHAR(20)
)
BEGIN
    
    SELECT  v.id_venta,
            v.folio_venta,
            v.fecha_venta,
            v.total,
            v.metodo_pago,
            v.cambio,
            v.requiere_ticket,
            v.estado,
            u.nombre_completo AS vendedor_nombre
    FROM    ventas   v
    JOIN    usuarios u ON u.id_usuario = v.vendedor_id
    WHERE   v.folio_venta = p_folio
    LIMIT   1;

    
    SELECT  dv.id_detalle_venta,
            p.nombre             AS producto_nombre,
            p.descripcion        AS producto_descripcion,
            dv.cantidad,
            dv.precio_unitario,
            dv.descuento_pct,
            dv.subtotal
    FROM    detalle_ventas dv
    JOIN    productos      p  ON p.id_producto  = dv.id_producto
    JOIN    ventas         v  ON v.id_venta     = dv.id_venta
    WHERE   v.folio_venta = p_folio
    ORDER   BY dv.id_detalle_venta;

    
    SELECT  t.id_ticket,
            t.contenido_json,
            t.impreso,
            t.generado_en
    FROM    tickets t
    JOIN    ventas  v ON v.id_venta = t.id_venta
    WHERE   v.folio_venta = p_folio
    LIMIT   1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_editar_materia_prima` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_editar_materia_prima`(
    IN  p_id_materia   INT,
    IN  p_nombre       VARCHAR(120)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_categoria    VARCHAR(60)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_unidad_base  VARCHAR(20)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_stock_minimo DECIMAL(12,4),
    IN  p_estatus      VARCHAR(10)    CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_ejecutado_por INT
)
BEGIN
    
    IF NOT EXISTS (
        SELECT 1 FROM materias_primas WHERE id_materia = p_id_materia
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La materia prima no existe.';
    END IF;

    
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de la materia prima es obligatorio.';
    END IF;

    
    IF p_unidad_base IS NULL OR TRIM(p_unidad_base) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La unidad base es obligatoria.';
    END IF;

    
    IF EXISTS (
        SELECT 1 FROM materias_primas
        WHERE  LOWER(nombre) = LOWER(TRIM(p_nombre))
          AND  id_materia    <> p_id_materia
        LIMIT  1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe otra materia prima con ese nombre.';
    END IF;

    UPDATE materias_primas
    SET nombre         = TRIM(p_nombre),
        categoria      = NULLIF(TRIM(p_categoria), ''),
        unidad_base    = TRIM(p_unidad_base),
        stock_minimo   = IFNULL(p_stock_minimo, stock_minimo),
        estatus        = IF(p_estatus IN ('activo', 'inactivo'), p_estatus, estatus),
        actualizado_en = NOW()
    WHERE id_materia = p_id_materia;

    
    INSERT INTO logs_sistema (
        tipo,         nivel,  id_usuario,     modulo,
        accion,       descripcion,            creado_en
    ) VALUES (
        'ajuste_inv', 'INFO', p_ejecutado_por, 'materias_primas',
        'EDITAR',
        CONCAT('Materia prima editada: ', TRIM(p_nombre), ' (id=', p_id_materia, ')'),
        NOW()
    );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_editar_producto` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_editar_producto`(
    IN  p_id_producto   INT,
    IN  p_nombre        VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    IN  p_descripcion   TEXT         CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    IN  p_precio_venta  DECIMAL(10,2),
    IN  p_ejecutado_por INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = p_id_producto) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El producto no existe.';
    END IF;

    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre del producto es obligatorio.';
    END IF;

    IF p_precio_venta IS NULL OR p_precio_venta <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El precio de venta debe ser mayor a 0.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM productos
        WHERE  LOWER(nombre) = LOWER(TRIM(p_nombre))
          AND  id_producto   <> p_id_producto
        LIMIT  1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe otro producto con ese nombre.';
    END IF;

    UPDATE productos
    SET nombre         = TRIM(p_nombre),
        descripcion    = NULLIF(TRIM(IFNULL(p_descripcion, '')), ''),
        precio_venta   = p_precio_venta,
        actualizado_en = NOW()
    WHERE id_producto = p_id_producto;

    INSERT INTO logs_sistema (
        tipo,    nivel,  id_usuario,     modulo,
        accion,  descripcion,            creado_en
    ) VALUES (
        'venta', 'INFO', p_ejecutado_por, 'productos',
        'EDITAR',
        CONCAT('Producto editado: ', TRIM(p_nombre), ' (id=', p_id_producto, ')'),
        NOW()
    );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_editar_proveedor` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_editar_proveedor`(
    IN  p_id_proveedor  INT,
    IN  p_nombre        VARCHAR(150)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_rfc           VARCHAR(13)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_contacto      VARCHAR(120)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_telefono      VARCHAR(20)   CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_email         VARCHAR(150)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_direccion     TEXT          CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_ejecutado_por INT
)
BEGIN
    
    IF NOT EXISTS (SELECT 1 FROM proveedores WHERE id_proveedor = p_id_proveedor) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El proveedor no existe.';
    END IF;

    
    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre del proveedor es obligatorio.';
    END IF;

    
    IF p_rfc IS NOT NULL AND TRIM(p_rfc) <> '' AND
       EXISTS (
           SELECT 1 FROM proveedores
           WHERE  rfc = TRIM(p_rfc)
             AND  id_proveedor <> p_id_proveedor
       ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe otro proveedor con ese RFC.';
    END IF;

    UPDATE proveedores
    SET nombre         = TRIM(p_nombre),
        rfc            = NULLIF(TRIM(p_rfc),       ''),
        contacto       = NULLIF(TRIM(p_contacto),  ''),
        telefono       = NULLIF(TRIM(p_telefono),  ''),
        email          = NULLIF(TRIM(p_email),     ''),
        direccion      = NULLIF(TRIM(p_direccion), ''),
        actualizado_en = NOW()
    WHERE id_proveedor = p_id_proveedor;

    
    INSERT INTO logs_sistema (
        tipo,    nivel,  id_usuario,     modulo,
        accion,  descripcion,            creado_en
    ) VALUES (
        'compra', 'INFO', p_ejecutado_por, 'proveedores',
        'EDITAR',
        CONCAT('Proveedor editado: ', TRIM(p_nombre), ' (id=', p_id_proveedor, ')'),
        NOW()
    );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_editar_receta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_editar_receta`(
    IN p_id_receta          INT,
    IN p_id_producto        INT,
    IN p_nombre             VARCHAR(120),
    IN p_descripcion        TEXT,
    IN p_rendimiento        DECIMAL(10,2),
    IN p_unidad_rendimiento VARCHAR(20),
    IN p_precio_venta       DECIMAL(10,2),
    IN p_ejecutado_por      INT
)
BEGIN
    -- ── Validaciones ──────────────────────────────────────────
    IF NOT EXISTS (SELECT 1 FROM recetas WHERE id_receta = p_id_receta) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La receta no existe.';
    END IF;

    IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de la receta es obligatorio.';
    END IF;

    IF p_rendimiento IS NULL OR p_rendimiento <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El rendimiento debe ser mayor a 0.';
    END IF;

    IF EXISTS (
        SELECT 1 FROM recetas
        WHERE  CONVERT(nombre USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
             = CONVERT(TRIM(p_nombre) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
          AND  id_receta <> p_id_receta
        LIMIT 1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ya existe otra receta con ese nombre.';
    END IF;

    -- ── Actualizar encabezado ─────────────────────────────────
    UPDATE recetas SET
        id_producto        = NULLIF(p_id_producto, 0),
        nombre             = TRIM(p_nombre),
        descripcion        = NULLIF(TRIM(IFNULL(p_descripcion, '')), ''),
        rendimiento        = p_rendimiento,
        unidad_rendimiento = p_unidad_rendimiento,
        precio_venta       = NULLIF(p_precio_venta, 0),
        actualizado_en     = NOW()
    WHERE id_receta = p_id_receta;

    -- ── Reemplazar detalles ───────────────────────────────────
    DELETE FROM detalle_recetas WHERE id_receta = p_id_receta;

    INSERT INTO detalle_recetas
        (id_receta, id_materia, id_unidad_presentacion,
         cantidad_presentacion, cantidad_requerida, orden)
    SELECT
        p_id_receta,
        id_materia,
        id_unidad_presentacion,
        cantidad_presentacion,
        cantidad_requerida,
        orden
    FROM tmp_insumos_receta;

    -- ── Auditoría ─────────────────────────────────────────────
    INSERT INTO logs_sistema (
        tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en
    ) VALUES (
        'produccion', 'INFO', p_ejecutado_por, 'recetas',
        'EDITAR',
        CONCAT('Receta editada: ', TRIM(p_nombre)),
        NOW()
    );

    -- ── Limpiar tabla temporal ────────────────────────────────
    DROP TEMPORARY TABLE IF EXISTS tmp_insumos_receta;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_editar_usuario` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_editar_usuario`(
    IN  p_id_usuario      INT,
    IN  p_nombre_completo VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_username        VARCHAR(60)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_id_rol          SMALLINT,
    IN  p_estatus         VARCHAR(10)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
    IN  p_password_hash   VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci
)
    SQL SECURITY INVOKER
BEGIN
    -- Verificar que el usuario exista
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_id_usuario) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El usuario no existe.';
    END IF;

    -- Verificar que el username no lo use OTRO usuario
    IF EXISTS (SELECT 1 FROM usuarios WHERE username = p_username AND id_usuario <> p_id_usuario) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El nombre de usuario ya esta en uso.';
    END IF;

    -- Verificar que el rol exista
    IF NOT EXISTS (SELECT 1 FROM roles WHERE id_rol = p_id_rol) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El rol seleccionado no es valido.';
    END IF;

    IF p_password_hash IS NOT NULL THEN
        UPDATE usuarios
        SET nombre_completo = p_nombre_completo,
            username        = p_username,
            id_rol          = p_id_rol,
            estatus         = p_estatus,
            password_hash   = p_password_hash,
            actualizado_en  = NOW()
        WHERE id_usuario = p_id_usuario;
    ELSE
        UPDATE usuarios
        SET nombre_completo = p_nombre_completo,
            username        = p_username,
            id_rol          = p_id_rol,
            estatus         = p_estatus,
            actualizado_en  = NOW()
        WHERE id_usuario = p_id_usuario;
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_estadisticas_mermas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_estadisticas_mermas`()
BEGIN
    
    SELECT COALESCE(SUM(cantidad), 0) AS total_hoy
    FROM mermas
    WHERE tipo_objeto = 'materia_prima'
      AND DATE(fecha_merma) = CURDATE();
    
    
    SELECT COALESCE(SUM(cantidad), 0) AS total_semana
    FROM mermas
    WHERE tipo_objeto = 'materia_prima'
      AND YEARWEEK(fecha_merma, 1) = YEARWEEK(CURDATE(), 1);
    
    
    SELECT causa, COUNT(*) AS cantidad, SUM(cantidad) AS total_perdido
    FROM mermas
    WHERE tipo_objeto = 'materia_prima'
    GROUP BY causa
    ORDER BY total_perdido DESC
    LIMIT 5;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_finalizar_compra` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_finalizar_compra`(
    IN p_id_compra     INT,
    IN p_ejecutado_por INT,
    IN p_folio_salida  VARCHAR(20) CHARACTER SET utf8mb4
)
BEGIN
    DECLARE v_estatus      VARCHAR(20);
    DECLARE v_total        DECIMAL(12,2);
    DECLARE v_id_proveedor INT;
    DECLARE v_fecha        DATE;
    DECLARE v_folio        VARCHAR(20);

    SELECT estatus, total, id_proveedor, fecha_compra, folio
    INTO   v_estatus, v_total, v_id_proveedor, v_fecha, v_folio
    FROM   compras WHERE id_compra = p_id_compra;

    IF v_estatus IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El pedido de compra no existe.';
    END IF;

    IF v_estatus <> 'ordenado' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se pueden finalizar pedidos en estatus ordenado.';
    END IF;

    
    UPDATE materias_primas mp
    JOIN detalle_compras dc ON dc.id_materia = mp.id_materia
    SET mp.stock_actual = mp.stock_actual + dc.cantidad_base
    WHERE dc.id_compra = p_id_compra;

    
    UPDATE compras
    SET estatus = 'finalizado'
    WHERE id_compra = p_id_compra;

    
    INSERT INTO salidas_efectivo (
        folio_salida, id_proveedor, id_compra, categoria,
        descripcion, monto, fecha_salida,
        estado, registrado_por, creado_en, actualizado_en
    ) VALUES (
        p_folio_salida,
        v_id_proveedor,
        p_id_compra,
        'compra_insumos',
        CONCAT('Pago pedido compra ', v_folio),
        v_total,
        v_fecha,
        'pendiente',
        p_ejecutado_por,
        NOW(),
        NOW()
    );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_finalizar_orden_produccion` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_finalizar_orden_produccion`(
  IN  p_id_produccion  INT,
  IN  p_finalizado_por INT,
  IN  p_piezas_reales  DECIMAL(10,2),   
  OUT p_ok             TINYINT(1),
  OUT p_mensaje        VARCHAR(500)
)
proc: BEGIN
  DECLARE v_estado         VARCHAR(20)   DEFAULT NULL;
  DECLARE v_folio          VARCHAR(20)   DEFAULT NULL;
  DECLARE v_id_receta      INT           DEFAULT NULL;
  DECLARE v_id_producto    INT           DEFAULT NULL;
  DECLARE v_cantidad_lotes DECIMAL(10,2) DEFAULT NULL;
  DECLARE v_piezas_esp     DECIMAL(10,2) DEFAULT NULL;
  DECLARE v_piezas_final   DECIMAL(10,2) DEFAULT NULL;
  DECLARE v_faltantes      INT           DEFAULT 0;
  DECLARE v_detalle_falt   VARCHAR(500)  DEFAULT '';

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 @v_sqlerr = MESSAGE_TEXT;
    ROLLBACK;
    DROP TEMPORARY TABLE IF EXISTS _tmp_insumos_fin;
    SET p_ok = 0;
    SET p_mensaje = CONCAT('Error al finalizar: ', COALESCE(@v_sqlerr, 'error desconocido'));
  END;

  SET p_ok = 0;

  
  SELECT estado, folio_lote, id_receta, id_producto,
         cantidad_lotes, piezas_esperadas
    INTO v_estado, v_folio, v_id_receta, v_id_producto,
         v_cantidad_lotes, v_piezas_esp
    FROM produccion
   WHERE id_produccion = p_id_produccion
   LIMIT 1;

  IF v_estado IS NULL THEN
    SET p_mensaje = CONCAT('No existe la orden con id = ', p_id_produccion, '.');
    LEAVE proc;
  END IF;

  IF v_estado != 'en_proceso' THEN
    SET p_mensaje = CONCAT('La orden ', v_folio, ' no puede finalizarse. ',
                           'Estado actual: ', v_estado,
                           '. Solo se pueden finalizar órdenes en proceso.');
    LEAVE proc;
  END IF;

  SET v_piezas_final = COALESCE(p_piezas_reales, v_piezas_esp);

  IF v_piezas_final <= 0 THEN
    SET p_mensaje = 'Las piezas producidas deben ser mayor a cero.';
    LEAVE proc;
  END IF;

  
  DROP TEMPORARY TABLE IF EXISTS _tmp_insumos_fin;

  CREATE TEMPORARY TABLE _tmp_insumos_fin (
    id_materia         INT           NOT NULL,
    cantidad_requerida DECIMAL(14,4) NOT NULL,
    PRIMARY KEY (id_materia)
  ) ENGINE=MEMORY;

  INSERT INTO _tmp_insumos_fin (id_materia, cantidad_requerida)
  SELECT dr.id_materia,
         ROUND(v_cantidad_lotes * dr.cantidad_requerida, 4)
    FROM detalle_recetas dr
   WHERE dr.id_receta = v_id_receta;

  IF (SELECT COUNT(*) FROM _tmp_insumos_fin) = 0 THEN
    DROP TEMPORARY TABLE IF EXISTS _tmp_insumos_fin;
    SET p_mensaje = 'La receta no tiene insumos configurados. No se puede finalizar.';
    LEAVE proc;
  END IF;

  
  SELECT COUNT(*) INTO v_faltantes
    FROM _tmp_insumos_fin t
    JOIN materias_primas  mp ON mp.id_materia = t.id_materia
   WHERE mp.stock_actual < t.cantidad_requerida;

  IF v_faltantes > 0 THEN
    SELECT GROUP_CONCAT(
             CONCAT(mp.nombre, ': necesita ', ROUND(t.cantidad_requerida, 2),
                    ' ', mp.unidad_base, ', disponible: ', ROUND(mp.stock_actual, 2))
             ORDER BY mp.nombre
             SEPARATOR ' | '
           )
      INTO v_detalle_falt
      FROM _tmp_insumos_fin t
      JOIN materias_primas  mp ON mp.id_materia = t.id_materia
     WHERE mp.stock_actual < t.cantidad_requerida;

    DROP TEMPORARY TABLE IF EXISTS _tmp_insumos_fin;
    SET p_ok = 0;
    SET p_mensaje = CONCAT('Stock insuficiente → ', v_detalle_falt);
    LEAVE proc;
  END IF;

  
  START TRANSACTION;

  
  SELECT id_materia
    FROM materias_primas
   WHERE id_materia IN (SELECT id_materia FROM _tmp_insumos_fin)
   FOR UPDATE;

  
  SELECT COUNT(*) INTO v_faltantes
    FROM _tmp_insumos_fin t
    JOIN materias_primas  mp ON mp.id_materia = t.id_materia
   WHERE mp.stock_actual < t.cantidad_requerida;

  IF v_faltantes > 0 THEN
    ROLLBACK;
    DROP TEMPORARY TABLE IF EXISTS _tmp_insumos_fin;
    SET p_ok     = 0;
    SET p_mensaje = 'El stock cambió durante el proceso. Intenta nuevamente.';
    LEAVE proc;
  END IF;

  
  UPDATE materias_primas mp
    JOIN _tmp_insumos_fin t ON t.id_materia = mp.id_materia
     SET mp.stock_actual    = mp.stock_actual - t.cantidad_requerida,
         mp.actualizado_en  = NOW();

  
  INSERT INTO detalle_produccion
    (id_produccion, id_materia, cantidad_requerida, cantidad_descontada)
  SELECT p_id_produccion, id_materia, cantidad_requerida, cantidad_requerida
    FROM _tmp_insumos_fin;

  
  
  INSERT INTO inventario_pt (id_producto, stock_actual, stock_minimo)
  VALUES (v_id_producto, v_piezas_final, 0)
  ON DUPLICATE KEY UPDATE
    stock_actual         = stock_actual + VALUES(stock_actual),
    ultima_actualizacion = NOW();

  
  UPDATE produccion
     SET estado            = 'finalizado',
         piezas_producidas = v_piezas_final,
         fecha_fin_real    = NOW()
   WHERE id_produccion = p_id_produccion;

  
  INSERT INTO logs_sistema (
    tipo, nivel, id_usuario, modulo, accion, descripcion,
    referencia_id, referencia_tipo, creado_en
  ) VALUES (
    'produccion', 'INFO', p_finalizado_por, 'Produccion', 'finalizar_orden',
    CONCAT('Orden ', v_folio, ' finalizada. Piezas producidas: ', v_piezas_final,
           '. Producto id=', v_id_producto, ' acreditado al inventario.'),
    p_id_produccion, 'produccion', NOW()
  );

  COMMIT;
  DROP TEMPORARY TABLE IF EXISTS _tmp_insumos_fin;

  SET p_ok      = 1;
  SET p_mensaje = CONCAT('Orden ', v_folio, ' finalizada. ',
                         v_piezas_final, ' piezas acreditadas al inventario.');
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_iniciar_orden_produccion` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_iniciar_orden_produccion`(
  IN  p_id_produccion INT,
  IN  p_iniciado_por  INT,
  OUT p_ok            TINYINT(1),
  OUT p_mensaje       VARCHAR(500)
)
proc: BEGIN
  DECLARE v_estado VARCHAR(20) DEFAULT NULL;
  DECLARE v_folio  VARCHAR(20) DEFAULT NULL;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    SET p_mensaje = 'Error inesperado al iniciar la orden.';
  END;

  SET p_ok = 0;

  SELECT estado, folio_lote
    INTO v_estado, v_folio
    FROM produccion
   WHERE id_produccion = p_id_produccion
   LIMIT 1;

  IF v_estado IS NULL THEN
    SET p_mensaje = CONCAT('No existe la orden con id = ', p_id_produccion, '.');
    LEAVE proc;
  END IF;

  IF v_estado != 'pendiente' THEN
    SET p_mensaje = CONCAT('La orden ', v_folio, ' no puede iniciarse. ',
                           'Estado actual: ', v_estado,
                           '. Solo se pueden iniciar órdenes en estado pendiente.');
    LEAVE proc;
  END IF;

  START TRANSACTION;

  UPDATE produccion
     SET estado       = 'en_proceso',
         fecha_inicio = NOW()
   WHERE id_produccion = p_id_produccion;

  INSERT INTO logs_sistema (
    tipo, nivel, id_usuario, modulo, accion, descripcion,
    referencia_id, referencia_tipo, creado_en
  ) VALUES (
    'produccion', 'INFO', p_iniciado_por, 'Produccion', 'iniciar_orden',
    CONCAT('Orden ', v_folio, ' iniciada — ahora está en proceso.'),
    p_id_produccion, 'produccion', NOW()
  );

  COMMIT;

  SET p_ok      = 1;
  SET p_mensaje = CONCAT('Orden ', v_folio, ' iniciada correctamente. Ya está en proceso.');
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_iniciar_produccion_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_iniciar_produccion_pedido`(
  IN  p_folio        VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_user         INT,
  OUT p_ok           TINYINT(1),
  OUT p_estado_nuevo VARCHAR(30),
  OUT p_error        VARCHAR(500),
  OUT p_faltantes    TEXT
)
sp_main: BEGIN
  DECLARE v_id_pedido   INT;
  DECLARE v_estado      VARCHAR(30);
  DECLARE v_id_tamanio  INT;
  DECLARE v_faltantes   INT     DEFAULT 0;
  DECLARE v_detalle_f   TEXT    DEFAULT '';
  DECLARE v_folio_prod  VARCHAR(20);
  DECLARE v_max_prod    INT     DEFAULT 0;
  DECLARE v_id_prod     INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
    SET p_estado_nuevo = NULL;
  END;
  SET p_ok=0; SET p_error=NULL; SET p_faltantes=NULL; SET p_estado_nuevo=NULL;
  SELECT id_pedido, estado, id_tamanio
    INTO v_id_pedido, v_estado, v_id_tamanio
    FROM pedidos WHERE folio = p_folio LIMIT 1;
  IF v_id_pedido IS NULL THEN
    SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
    LEAVE sp_main;
  END IF;
  IF v_estado NOT IN ('aprobado','pendiente_insumos') THEN
    SET p_error = CONCAT('Estado inválido para iniciar: ', v_estado);
    LEAVE sp_main;
  END IF;
  DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;
  CREATE TEMPORARY TABLE _tmp_ins_pedido (
    id_materia INT NOT NULL, cantidad_requerida DECIMAL(14,4) NOT NULL, PRIMARY KEY(id_materia)
  ) ENGINE=MEMORY;
  INSERT INTO _tmp_ins_pedido (id_materia, cantidad_requerida)
  SELECT dr.id_materia,
         ROUND(SUM((dp.cantidad / r.rendimiento) * dr.cantidad_requerida), 4)
    FROM detalle_pedidos dp
    JOIN recetas r ON r.id_producto = dp.id_producto AND r.estatus = 'activo'
                  AND ((v_id_tamanio IS NOT NULL AND r.id_tamanio = v_id_tamanio)
                       OR (v_id_tamanio IS NULL AND r.id_tamanio IS NULL))
    JOIN detalle_recetas dr ON dr.id_receta = r.id_receta
   WHERE dp.id_pedido = v_id_pedido
   GROUP BY dr.id_materia;
  IF (SELECT COUNT(*) FROM _tmp_ins_pedido) = 0 THEN
    DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;
    SET p_error = 'No se encontraron recetas para los productos del pedido.';
    LEAVE sp_main;
  END IF;
  SELECT COUNT(*) INTO v_faltantes
    FROM _tmp_ins_pedido t JOIN materias_primas mp ON mp.id_materia = t.id_materia
   WHERE mp.stock_actual < t.cantidad_requerida;
  IF v_faltantes > 0 THEN
    SELECT GROUP_CONCAT(
      CONCAT(mp.nombre,': necesita ',ROUND(t.cantidad_requerida,2),' ',mp.unidad_base,
             ', disponible: ',ROUND(mp.stock_actual,2),' ',mp.unidad_base,
             ' (faltan ',ROUND(t.cantidad_requerida-mp.stock_actual,2),')')
      ORDER BY mp.nombre SEPARATOR ' | ')
      INTO v_detalle_f
      FROM _tmp_ins_pedido t JOIN materias_primas mp ON mp.id_materia = t.id_materia
     WHERE mp.stock_actual < t.cantidad_requerida;
    START TRANSACTION;
    UPDATE pedidos SET estado='pendiente_insumos', actualizado_en=NOW() WHERE id_pedido=v_id_pedido;
    INSERT INTO historial_pedidos(id_pedido,estado_antes,estado_despues,nota,realizado_por,creado_en)
    VALUES(v_id_pedido,v_estado,'pendiente_insumos',
           CONCAT('Insumos insuficientes: ',v_detalle_f),p_user,NOW());
    COMMIT;
    DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;
    SET p_ok=1; SET p_estado_nuevo='pendiente_insumos'; SET p_faltantes=v_detalle_f;
    LEAVE sp_main;
  END IF;
  START TRANSACTION;
  SELECT id_materia FROM materias_primas
   WHERE id_materia IN (SELECT id_materia FROM _tmp_ins_pedido) FOR UPDATE;
  SELECT COUNT(*) INTO v_faltantes
    FROM _tmp_ins_pedido t JOIN materias_primas mp ON mp.id_materia=t.id_materia
   WHERE mp.stock_actual < t.cantidad_requerida;
  IF v_faltantes > 0 THEN
    ROLLBACK; DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;
    SET p_ok=0; SET p_error='El stock cambió durante el proceso. Intenta nuevamente.';
    LEAVE sp_main;
  END IF;
  UPDATE materias_primas mp JOIN _tmp_ins_pedido t ON t.id_materia=mp.id_materia
     SET mp.stock_actual=mp.stock_actual-t.cantidad_requerida, mp.actualizado_en=NOW();
  SELECT COALESCE(MAX(id_produccion),0) INTO v_max_prod FROM produccion;
  SET v_folio_prod = CONCAT('L-',LPAD(v_max_prod+1,4,'0'));
  WHILE EXISTS(SELECT 1 FROM produccion WHERE folio_lote=v_folio_prod) DO
    SET v_max_prod=v_max_prod+1;
    SET v_folio_prod=CONCAT('L-',LPAD(v_max_prod+1,4,'0'));
  END WHILE;
  INSERT INTO produccion(folio_lote,id_producto,id_receta,cantidad_lotes,piezas_esperadas,
    piezas_producidas,estado,fecha_inicio,operario_id,observaciones,creado_en,creado_por)
  SELECT v_folio_prod,dp.id_producto,r.id_receta,
    ROUND(dp.cantidad/r.rendimiento,4),dp.cantidad,
    NULL,'en_proceso',NOW(),p_user,CONCAT('Pedido ',p_folio),NOW(),p_user
  FROM detalle_pedidos dp
  JOIN recetas r ON r.id_producto=dp.id_producto AND r.estatus='activo'
               AND ((v_id_tamanio IS NOT NULL AND r.id_tamanio=v_id_tamanio)
                    OR (v_id_tamanio IS NULL AND r.id_tamanio IS NULL))
  WHERE dp.id_pedido=v_id_pedido LIMIT 1;
  SET v_id_prod=LAST_INSERT_ID();
  INSERT INTO detalle_produccion(id_produccion,id_materia,cantidad_requerida,cantidad_descontada)
  SELECT v_id_prod,id_materia,cantidad_requerida,cantidad_requerida FROM _tmp_ins_pedido;
  UPDATE pedidos SET estado='en_produccion',atendido_por=p_user,actualizado_en=NOW()
   WHERE id_pedido=v_id_pedido;
  INSERT INTO historial_pedidos(id_pedido,estado_antes,estado_despues,nota,realizado_por,creado_en)
  VALUES(v_id_pedido,v_estado,'en_produccion',
         CONCAT('Producción iniciada. Lote: ',v_folio_prod),p_user,NOW());
  INSERT INTO logs_sistema(tipo,nivel,id_usuario,modulo,accion,descripcion,
    referencia_id,referencia_tipo,creado_en)
  VALUES('produccion','INFO',p_user,'Pedidos','iniciar_produccion',
    CONCAT('Pedido ',p_folio,' → en_produccion. Lote: ',v_folio_prod),
    v_id_pedido,'pedidos',NOW());
  COMMIT;
  DROP TEMPORARY TABLE IF EXISTS _tmp_ins_pedido;
  SET p_ok=1; SET p_estado_nuevo='en_produccion';
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_kpi_costo_utilidad` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_kpi_costo_utilidad`()
BEGIN
    
    DROP TEMPORARY TABLE IF EXISTS _tmp_kpi_precio_real;
    CREATE TEMPORARY TABLE _tmp_kpi_precio_real AS
    SELECT dv.id_producto, ROUND(AVG(dv.precio_unitario), 2) AS precio_real
    FROM detalle_ventas dv
    INNER JOIN ventas v ON v.id_venta = dv.id_venta
    WHERE v.estado = 'completada'
      AND DATE(v.fecha_venta) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY dv.id_producto;

    
    
    DROP TEMPORARY TABLE IF EXISTS _tmp_kpi_precio_real2;
    CREATE TEMPORARY TABLE _tmp_kpi_precio_real2 AS
    SELECT * FROM _tmp_kpi_precio_real;

    SELECT
        COUNT(DISTINCT p.id_producto)                             AS total_productos,
        ROUND(AVG(mc.margen_pct), 2)                             AS margen_prom,
        ROUND(AVG(mc.costo_unitario), 2)                         AS costo_prom,
        ROUND(AVG(COALESCE(pvr.precio_real, p.precio_venta)), 2) AS precio_prom,
        SUM(CASE WHEN mc.margen_pct < 20 THEN 1 ELSE 0 END)     AS productos_margen_bajo
    FROM productos p
    INNER JOIN recetas r
           ON  r.id_producto = p.id_producto
           AND r.estatus     = 'activo'
    LEFT JOIN _tmp_kpi_precio_real pvr ON pvr.id_producto = p.id_producto
    INNER JOIN (
        SELECT
            r2.id_receta,
            r2.id_producto,
            ROUND(
                COALESCE(tcr.costo_total_lote, 0) / r2.rendimiento,
                4
            )                                                         AS costo_unitario,
            CASE
                WHEN COALESCE(pvr2.precio_real, p2.precio_venta) > 0 THEN
                    ROUND(
                        (COALESCE(pvr2.precio_real, p2.precio_venta)
                            - COALESCE(tcr.costo_total_lote, 0) / r2.rendimiento)
                        / COALESCE(pvr2.precio_real, p2.precio_venta) * 100,
                        2
                    )
                ELSE 0
            END                                                       AS margen_pct
        FROM recetas r2
        INNER JOIN productos p2
               ON  p2.id_producto = r2.id_producto
               AND p2.estatus     = 'activo'
        LEFT JOIN _tmp_kpi_precio_real2 pvr2 ON pvr2.id_producto = p2.id_producto
        LEFT JOIN (
            SELECT
                dr.id_receta,
                ROUND(SUM(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0)), 4)
                    AS costo_total_lote
            FROM detalle_recetas dr
            LEFT JOIN v_costo_promedio_materia cpm
                   ON cpm.id_materia = dr.id_materia
            GROUP BY dr.id_receta
        ) tcr ON tcr.id_receta = r2.id_receta
        WHERE r2.estatus = 'activo'
    ) mc ON mc.id_receta = r.id_receta
    WHERE p.estatus = 'activo';

    DROP TEMPORARY TABLE IF EXISTS _tmp_kpi_precio_real;
    DROP TEMPORARY TABLE IF EXISTS _tmp_kpi_precio_real2;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_limpiar_detalles_compra` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_limpiar_detalles_compra`(
    IN p_id_compra INT
)
BEGIN
    DECLARE v_estatus VARCHAR(20);
    SELECT estatus INTO v_estatus FROM compras WHERE id_compra = p_id_compra;
    IF v_estatus IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Pedido no encontrado.';
    END IF;
    IF v_estatus != 'ordenado' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Solo se pueden editar pedidos en estatus Ordenado.';
    END IF;
    DELETE FROM detalle_compras WHERE id_compra = p_id_compra;
    UPDATE compras SET total = 0 WHERE id_compra = p_id_compra;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_listar_mermas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_listar_mermas`(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_causa VARCHAR(30),
    IN p_offset INT,
    IN p_limit INT
)
BEGIN
    SELECT 
        m.id_merma,
        mp.nombre AS materia_nombre,
        m.cantidad,
        m.unidad,
        m.causa,
        m.descripcion,
        m.fecha_merma,
        u.nombre_completo AS registrado_por_nombre,
        COUNT(*) OVER () AS total_filas
    FROM mermas m
    JOIN materias_primas mp ON mp.id_materia = m.id_referencia
    JOIN usuarios u ON u.id_usuario = m.registrado_por
    WHERE m.tipo_objeto = 'materia_prima'
      AND (p_fecha_inicio IS NULL OR DATE(m.fecha_merma) >= p_fecha_inicio)
      AND (p_fecha_fin IS NULL OR DATE(m.fecha_merma) <= p_fecha_fin)
      AND (p_causa IS NULL OR p_causa = '' OR m.causa = p_causa)
    ORDER BY m.fecha_merma DESC
    LIMIT p_limit OFFSET p_offset;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_listar_mermas_productos` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_listar_mermas_productos`(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    IN p_causa VARCHAR(30),
    IN p_offset INT,
    IN p_limit INT
)
BEGIN
    SELECT 
        m.id_merma,
        p.nombre AS producto_nombre,
        m.cantidad,
        m.unidad,
        m.causa,
        m.descripcion,
        m.fecha_merma,
        u.nombre_completo AS registrado_por_nombre,
        COUNT(*) OVER () AS total_filas
    FROM mermas m
    JOIN productos p ON p.id_producto = m.id_referencia
    JOIN usuarios u ON u.id_usuario = m.registrado_por
    WHERE m.tipo_objeto = 'producto_terminado'
      AND (p_fecha_inicio IS NULL OR DATE(m.fecha_merma) >= p_fecha_inicio)
      AND (p_fecha_fin IS NULL OR DATE(m.fecha_merma) <= p_fecha_fin)
      AND (p_causa IS NULL OR p_causa = '' OR m.causa = p_causa)
    ORDER BY m.fecha_merma DESC
    LIMIT p_limit OFFSET p_offset;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_lista_ordenes_produccion` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_lista_ordenes_produccion`(
  IN p_estado      VARCHAR(20),
  IN p_fecha_ini   DATE,
  IN p_fecha_fin   DATE,
  IN p_limit       INT,
  IN p_offset      INT
)
BEGIN
  SET p_limit  = COALESCE(p_limit,  20);
  SET p_offset = COALESCE(p_offset, 0);

  SELECT
    p.id_produccion,
    p.folio_lote,
    r.id_receta,
    r.nombre                             AS nombre_receta,
    pr.nombre                            AS nombre_producto,
    p.cantidad_lotes,
    p.piezas_esperadas,
    p.piezas_producidas,
    p.estado,
    p.fecha_inicio,
    p.fecha_fin_estimado,
    p.fecha_fin_real,
    p.creado_en,
    p.observaciones,
    u_op.nombre_completo                 AS operario,
    u_cr.nombre_completo                 AS creado_por_nombre,
    
    (SELECT COUNT(*)
       FROM detalle_pedidos dp
       JOIN pedidos         ped ON ped.id_pedido = dp.id_pedido
      WHERE dp.id_producto = p.id_producto
        AND ped.estado IN ('pendiente','aprobado','en_produccion')
    )                                    AS pedidos_pendientes
  FROM produccion    p
  JOIN recetas       r   ON r.id_receta    = p.id_receta
  JOIN productos     pr  ON pr.id_producto = p.id_producto
  LEFT JOIN usuarios u_op ON u_op.id_usuario = p.operario_id
  LEFT JOIN usuarios u_cr ON u_cr.id_usuario = p.creado_por
  WHERE (p_estado    IS NULL OR p.estado         = p_estado)
    AND (p_fecha_ini IS NULL OR DATE(p.creado_en) >= p_fecha_ini)
    AND (p_fecha_fin IS NULL OR DATE(p.creado_en) <= p_fecha_fin)
  ORDER BY
    FIELD(p.estado, 'en_proceso', 'pendiente', 'finalizado', 'cancelado'),
    p.creado_en DESC
  LIMIT  p_limit
  OFFSET p_offset;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_lista_pedidos_interna` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_lista_pedidos_interna`(
  IN p_estado VARCHAR(20) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN p_fecha  DATE,
  IN p_buscar VARCHAR(100) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci
)
BEGIN
  SELECT
    p.id_pedido,
    p.folio                                          COLLATE utf8mb4_unicode_ci AS folio,
    p.estado                                         COLLATE utf8mb4_unicode_ci AS estado,
    p.fecha_recogida,
    p.total_estimado,
    p.creado_en,
    p.tipo                                           COLLATE utf8mb4_unicode_ci AS tipo_caja,
    t.nombre                                         COLLATE utf8mb4_unicode_ci AS tamanio_nombre,
    t.capacidad,
    u.nombre_completo                                COLLATE utf8mb4_unicode_ci AS cliente_nombre
  FROM  pedidos              p
  JOIN  usuarios             u  ON u.id_usuario  = p.id_cliente
  LEFT JOIN tamanios_charola t  ON t.id_tamanio  = p.id_tamanio
  WHERE (p_estado IS NULL OR p.estado COLLATE utf8mb4_unicode_ci = p_estado)
    AND (p_fecha  IS NULL OR DATE(p.fecha_recogida) = p_fecha)
    AND (p_buscar IS NULL
         OR p.folio           COLLATE utf8mb4_unicode_ci LIKE CONCAT('%', p_buscar, '%')
         OR u.nombre_completo COLLATE utf8mb4_unicode_ci LIKE CONCAT('%', p_buscar, '%'))
  ORDER BY p.creado_en DESC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_lista_ventas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_lista_ventas`(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin    DATE,
    IN p_metodo_pago  VARCHAR(20),
    IN p_estado       VARCHAR(20),
    IN p_vendedor_id  INT,
    IN p_offset       INT,
    IN p_limit        INT
)
BEGIN
    -- Ventas registradas (de la tabla ventas)
    SELECT
        v.id_venta,
        v.folio_venta,
        v.fecha_venta,
        v.total,
        v.metodo_pago,
        v.cambio,
        v.estado,
        v.requiere_ticket,
        u.nombre_completo AS vendedor_nombre,
        COUNT(dv.id_detalle_venta) AS num_productos,
        COUNT(*) OVER () AS total_filas,
        NULL AS pedido_origen
    FROM ventas v
    JOIN usuarios u ON u.id_usuario = v.vendedor_id
    LEFT JOIN detalle_ventas dv ON dv.id_venta = v.id_venta
    WHERE (p_fecha_inicio IS NULL OR DATE(v.fecha_venta) >= p_fecha_inicio)
      AND (p_fecha_fin    IS NULL OR DATE(v.fecha_venta) <= p_fecha_fin)
      AND (p_metodo_pago  IS NULL OR p_metodo_pago = '' OR v.metodo_pago = p_metodo_pago)
      AND (p_estado       IS NULL OR p_estado      = '' OR v.estado = p_estado)
      AND (p_vendedor_id  IS NULL OR p_vendedor_id = 0  OR v.vendedor_id = p_vendedor_id)
    GROUP BY v.id_venta
    UNION ALL
    -- Pedidos entregados que aún no tienen venta registrada
    SELECT
        NULL AS id_venta,
        CONCAT(p.folio) AS folio_venta,
        p.actualizado_en AS fecha_venta,
        p.total_estimado AS total,
        0 AS cambio,
        'completada' AS estado,
        1 AS requiere_ticket,
        u.nombre_completo AS vendedor_nombre,
        COUNT(dp.id_detalle) AS num_productos,
        0 AS total_filas,
        p.folio AS pedido_origen
    FROM pedidos p
    JOIN usuarios u ON u.id_usuario = p.atendido_por
    LEFT JOIN detalle_pedidos dp ON dp.id_pedido = p.id_pedido
    WHERE p.estado = 'entregado'
      AND NOT EXISTS (
          SELECT 1 FROM logs_sistema 
          WHERE referencia_id = p.id_pedido 
            AND referencia_tipo = 'pedido' 
            AND accion = 'venta_automatica'
      )
      AND (p_fecha_inicio IS NULL OR DATE(p.actualizado_en) >= p_fecha_inicio)
      AND (p_fecha_fin    IS NULL OR DATE(p.actualizado_en) <= p_fecha_fin)
    GROUP BY p.id_pedido
    ORDER BY fecha_venta DESC
    LIMIT p_limit OFFSET p_offset;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_marcar_entregado_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_marcar_entregado_pedido`(
  IN  p_folio VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_user  INT,
  OUT p_ok    TINYINT(1),
  OUT p_error VARCHAR(300)
)
sp_main: BEGIN
  DECLARE v_id_pedido  INT;
  DECLARE v_estado     VARCHAR(30);
  DECLARE v_id_cliente INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
  END;

  SET p_ok = 0; SET p_error = NULL;

  SELECT id_pedido, estado, id_cliente
    INTO v_id_pedido, v_estado, v_id_cliente
    FROM pedidos WHERE folio = p_folio LIMIT 1;

  IF v_id_pedido IS NULL THEN
    SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
    LEAVE sp_main;
  END IF;

  IF v_estado != 'listo' THEN
    SET p_error = CONCAT('Solo se pueden entregar pedidos listos. Estado: ', v_estado);
    LEAVE sp_main;
  END IF;

  START TRANSACTION;

    UPDATE pedidos
       SET estado = 'entregado', actualizado_en = NOW()
     WHERE id_pedido = v_id_pedido;

    INSERT INTO historial_pedidos
      (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
    VALUES
      (v_id_pedido, 'listo', 'entregado', 'Pedido entregado al cliente.', p_user, NOW());

    INSERT INTO notificaciones_pedidos
      (id_pedido, id_usuario, folio, tipo, mensaje, leida, creado_en)
    VALUES
      (v_id_pedido, v_id_cliente, p_folio, 'entregado',
       CONCAT('📦 Tu pedido ', p_folio, ' ha sido entregado. ¡Gracias!'),
       0, NOW());

  COMMIT;
  SET p_ok = 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_marcar_listo_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_marcar_listo_pedido`(
  IN  p_folio VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_user  INT,
  OUT p_ok    TINYINT(1),
  OUT p_error VARCHAR(300)
)
sp_main: BEGIN
  DECLARE v_id_pedido  INT;
  DECLARE v_estado     VARCHAR(30);
  DECLARE v_id_cliente INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
  END;

  SET p_ok = 0; SET p_error = NULL;

  SELECT id_pedido, estado, id_cliente
    INTO v_id_pedido, v_estado, v_id_cliente
    FROM pedidos WHERE folio = p_folio LIMIT 1;

  IF v_id_pedido IS NULL THEN
    SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
    LEAVE sp_main;
  END IF;

  IF v_estado != 'aprobado' THEN
    SET p_error = CONCAT('Solo se pueden marcar como listos los pedidos aprobados. Estado: ', v_estado);
    LEAVE sp_main;
  END IF;

  START TRANSACTION;

    UPDATE pedidos
       SET estado = 'listo', actualizado_en = NOW()
     WHERE id_pedido = v_id_pedido;

    INSERT INTO historial_pedidos
      (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
    VALUES
      (v_id_pedido, 'aprobado', 'listo', 'Pedido listo para recoger.', p_user, NOW());

    INSERT INTO notificaciones_pedidos
      (id_pedido, id_usuario, folio, tipo, mensaje, leida, creado_en)
    VALUES
      (v_id_pedido, v_id_cliente, p_folio, 'listo',
       CONCAT('🎉 ¡Tu pedido ', p_folio, ' está listo! Pasa a recogerlo.'),
       0, NOW());

    INSERT INTO logs_sistema
      (tipo, nivel, id_usuario, modulo, accion, descripcion,
       referencia_id, referencia_tipo, creado_en)
    VALUES
      ('pedido', 'INFO', p_user, 'Pedidos', 'marcar_listo',
       CONCAT('Pedido ', p_folio, ' marcado como listo.'),
       v_id_pedido, 'pedidos', NOW());

  COMMIT;
  SET p_ok = 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_marcar_notifs_leidas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_marcar_notifs_leidas`(IN p_usuario INT)
BEGIN
  UPDATE notificaciones_pedidos
  SET    leida = 1
  WHERE  id_usuario = p_usuario AND leida = 0;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_mermas_materias_primas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_mermas_materias_primas`(
    IN p_busqueda VARCHAR(120)
)
BEGIN
    SELECT 
        mp.id_materia,
        mp.nombre,
        mp.unidad_base,
        mp.stock_actual,
        mp.stock_minimo
    FROM materias_primas mp
    WHERE mp.estatus = 'activo'
      AND (p_busqueda IS NULL 
           OR p_busqueda = '' 
           OR CONVERT(mp.nombre USING utf8mb4) COLLATE utf8mb4_unicode_ci LIKE CONCAT('%', p_busqueda, '%'))
    ORDER BY mp.nombre;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_mermas_productos_terminados` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_mermas_productos_terminados`(
    IN p_busqueda VARCHAR(120)
)
BEGIN
    SELECT 
        p.id_producto,
        p.nombre,
        p.precio_venta,
        COALESCE(i.stock_actual, 0) AS stock_actual,
        COALESCE(i.stock_minimo, 0) AS stock_minimo,
        p.imagen_url
    FROM productos p
    LEFT JOIN inventario_pt i ON i.id_producto = p.id_producto
    WHERE p.estatus = 'activo'
      AND (p_busqueda IS NULL 
           OR p_busqueda = '' 
           OR CONVERT(p.nombre USING utf8mb4) COLLATE utf8mb4_unicode_ci LIKE CONCAT('%', p_busqueda, '%'))
    ORDER BY p.nombre;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_mis_pedidos_cliente` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_mis_pedidos_cliente`(IN p_cliente INT)
BEGIN
  
  SELECT
    p.id_pedido,
    p.folio,
    p.estado,
    p.fecha_recogida,
    p.total_estimado,
    p.motivo_rechazo,
    p.creado_en,
    p.metodo_pago,
    GROUP_CONCAT(
      CONCAT(pr.nombre, ' ×', CAST(dp.cantidad AS SIGNED))
      ORDER BY dp.id_detalle
      SEPARATOR ', '
    ) COLLATE utf8mb4_unicode_ci AS panes_resumen,
    IFNULL(SUM(dp.cantidad), 0) AS total_piezas
  FROM  pedidos p
  LEFT JOIN detalle_pedidos dp ON dp.id_pedido   = p.id_pedido
  LEFT JOIN productos       pr ON pr.id_producto = dp.id_producto
  WHERE p.id_cliente = p_cliente
  GROUP BY
    p.id_pedido, p.folio, p.estado, p.fecha_recogida,
    p.total_estimado, p.motivo_rechazo, p.creado_en, p.metodo_pago
  ORDER BY p.creado_en DESC;

  
  SELECT id_notif, id_pedido, folio, mensaje, leida, creado_en
  FROM   v_notificaciones_cliente
  WHERE  id_usuario = p_cliente
  LIMIT  50;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_notificaciones_cliente` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_notificaciones_cliente`(IN p_usuario INT)
BEGIN
  SELECT id_notif, id_pedido, folio, mensaje, leida, creado_en
  FROM   v_notificaciones_cliente
  WHERE  id_usuario = p_usuario
  LIMIT  50;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_pd_calcular_insumos` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_pd_calcular_insumos`(
  IN  p_id_pd   INT,
  OUT p_ok      TINYINT(1),
  OUT p_mensaje VARCHAR(500)
)
proc: BEGIN
  DECLARE v_folio           VARCHAR(20);
  DECLARE v_estado          VARCHAR(20);
  DECLARE v_tiene_faltantes TINYINT(1) DEFAULT 0;
  DECLARE v_total_piezas    INT        DEFAULT 0;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_mensaje = MESSAGE_TEXT;
  END;

  SET p_ok = 0;

  SELECT estado, folio INTO v_estado, v_folio
  FROM   produccion_diaria WHERE id_pd = p_id_pd LIMIT 1;

  IF v_estado IS NULL THEN
    SET p_mensaje = 'Producción no encontrada.'; LEAVE proc;
  END IF;

  IF v_estado <> 'pendiente' THEN
    SET p_mensaje = CONCAT('Solo se pueden calcular insumos en estado pendiente. Estado: ', v_estado);
    LEAVE proc;
  END IF;

  START TRANSACTION;

  -- Total de piezas (suma directa de cantidad_piezas)
  SELECT COALESCE(SUM(cantidad_piezas), 0)
    INTO v_total_piezas
    FROM produccion_diaria_detalle
   WHERE id_pd = p_id_pd;

  -- Borrar cálculo anterior (idempotente)
  DELETE FROM produccion_diaria_insumos WHERE id_pd = p_id_pd;

  -- Calcular insumos: piezas × (cantidad_requerida / rendimiento) por materia
  INSERT INTO produccion_diaria_insumos
    (id_pd, id_materia, cantidad_requerida, cantidad_descontada)
  SELECT
    p_id_pd,
    dr.id_materia,
    ROUND(SUM(pdd.cantidad_piezas * dr.cantidad_requerida / r.rendimiento), 4),
    0
  FROM  produccion_diaria_detalle pdd
  JOIN  recetas                   r   ON r.id_receta  = pdd.id_receta
  JOIN  detalle_recetas           dr  ON dr.id_receta = r.id_receta
  WHERE pdd.id_pd = p_id_pd
  GROUP BY dr.id_materia;

  -- ¿Hay algún insumo insuficiente?
  SELECT 1 INTO v_tiene_faltantes
  FROM   produccion_diaria_insumos pdi
  JOIN   materias_primas mp ON mp.id_materia = pdi.id_materia
  WHERE  pdi.id_pd = p_id_pd
    AND  mp.stock_actual < pdi.cantidad_requerida
  LIMIT  1;

  -- Actualizar encabezado
  UPDATE produccion_diaria
  SET    alerta_insumos         = COALESCE(v_tiene_faltantes, 0),
         total_cajas            = 0,
         total_piezas_esperadas = v_total_piezas
  WHERE  id_pd = p_id_pd;

  COMMIT;

  SET p_ok = 1;
  SET p_mensaje = IF(
    COALESCE(v_tiene_faltantes, 0) = 1,
    CONCAT('Producción ', v_folio, ' registrada con ALERTA de insumos insuficientes.'),
    CONCAT('Producción ', v_folio, ' lista. Stock suficiente para todos los insumos.')
  );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_pd_cancelar` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_pd_cancelar`(
  IN  p_id_pd   INT,
  IN  p_usuario INT,
  IN  p_motivo  TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  OUT p_ok      TINYINT(1),
  OUT p_mensaje VARCHAR(500)
)
proc: BEGIN
  DECLARE v_estado   VARCHAR(20);
  DECLARE v_folio    VARCHAR(20);
  DECLARE v_desc_in  TINYINT(1);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_mensaje = MESSAGE_TEXT;
  END;

  SET p_ok = 0;

  SELECT estado, folio, insumos_descontados
    INTO v_estado, v_folio, v_desc_in
    FROM produccion_diaria WHERE id_pd = p_id_pd LIMIT 1;

  IF v_estado IS NULL THEN
    SET p_mensaje = 'Producción no encontrada.'; LEAVE proc;
  END IF;

  IF v_estado NOT IN ('pendiente', 'en_proceso') THEN
    SET p_mensaje = CONCAT('La producción ', v_folio,
      ' no puede cancelarse. Estado: ', v_estado, '.');
    LEAVE proc;
  END IF;

  START TRANSACTION;

  -- Restaurar insumos si ya fueron descontados
  IF v_desc_in = 1 THEN
    UPDATE materias_primas mp
    JOIN   produccion_diaria_insumos pdi ON pdi.id_materia = mp.id_materia
    SET    mp.stock_actual   = mp.stock_actual + pdi.cantidad_descontada,
           mp.actualizado_en = NOW()
    WHERE  pdi.id_pd = p_id_pd AND pdi.cantidad_descontada > 0;
  END IF;

  -- Actualizar encabezado
  UPDATE produccion_diaria
  SET    estado              = 'cancelado',
         motivo_cancelacion  = COALESCE(NULLIF(TRIM(p_motivo), ''), 'Sin motivo'),
         insumos_descontados = IF(v_desc_in = 1, 0, 0)  -- marcar restaurados
  WHERE  id_pd = p_id_pd;

  COMMIT;

  SET p_ok     = 1;
  SET p_mensaje = CONCAT('Producción ', v_folio, ' cancelada.',
    IF(v_desc_in = 1, ' Insumos restaurados al almacén.', ''));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_pd_crear_cabecera` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_pd_crear_cabecera`(
  IN  p_nombre        VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  IN  p_observaciones TEXT        CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  IN  p_operario_id   INT,
  IN  p_creado_por    INT,
  OUT p_id_pd         INT,
  OUT p_folio         VARCHAR(20),
  OUT p_ok            TINYINT(1),
  OUT p_mensaje       VARCHAR(500)
)
proc: BEGIN
  DECLARE v_siguiente INT DEFAULT 1;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_mensaje = MESSAGE_TEXT;
  END;

  SET p_ok = 0;

  IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
    SET p_mensaje = 'El nombre de la producción es obligatorio.';
    LEAVE proc;
  END IF;

  SELECT COALESCE(MAX(CAST(SUBSTRING(folio, 4) AS UNSIGNED)), 0) + 1
    INTO v_siguiente
    FROM produccion_diaria;

  SET p_folio = CONCAT('PD-', LPAD(v_siguiente, 4, '0'));

  START TRANSACTION;

  INSERT INTO produccion_diaria
    (folio, nombre, observaciones, operario_id, creado_por, creado_en, actualizado_en)
  VALUES
    (p_folio, TRIM(p_nombre),
     NULLIF(TRIM(COALESCE(p_observaciones, '')), ''),
     NULLIF(p_operario_id, 0),
     p_creado_por, NOW(), NOW());

  SET p_id_pd = LAST_INSERT_ID();

  COMMIT;

  SET p_ok      = 1;
  SET p_mensaje = CONCAT('Cabecera creada con folio ', p_folio, '.');
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_pd_finalizar` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_pd_finalizar`(
  IN  p_id_pd   INT,
  IN  p_usuario INT,
  OUT p_ok      TINYINT(1),
  OUT p_mensaje VARCHAR(500)
)
proc: BEGIN
  DECLARE v_estado VARCHAR(20);
  DECLARE v_folio  VARCHAR(20);
  DECLARE v_piezas INT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_mensaje = MESSAGE_TEXT;
  END;

  SET p_ok = 0;

  SELECT estado, folio, total_piezas_esperadas
    INTO v_estado, v_folio, v_piezas
    FROM produccion_diaria WHERE id_pd = p_id_pd LIMIT 1;

  IF v_estado IS NULL THEN
    SET p_mensaje = 'Producción no encontrada.'; LEAVE proc;
  END IF;

  IF v_estado <> 'en_proceso' THEN
    SET p_mensaje = CONCAT('La producción ', v_folio,
      ' no está en proceso. Estado actual: ', v_estado, '.');
    LEAVE proc;
  END IF;

  START TRANSACTION;

  -- Acreditar inventario de producto terminado por producto
  INSERT INTO inventario_pt (id_producto, stock_actual, stock_minimo, ultima_actualizacion)
  SELECT pdd.id_producto, SUM(pdd.cantidad_piezas), 0, NOW()
  FROM   produccion_diaria_detalle pdd
  WHERE  pdd.id_pd = p_id_pd
  GROUP  BY pdd.id_producto
  ON DUPLICATE KEY UPDATE
    stock_actual         = stock_actual + VALUES(stock_actual),
    ultima_actualizacion = NOW();

  -- Actualizar encabezado
  UPDATE produccion_diaria
  SET    estado                = 'finalizado',
         fecha_fin_real        = NOW(),
         inventario_acreditado = 1
  WHERE  id_pd = p_id_pd;

  COMMIT;

  SET p_ok     = 1;
  SET p_mensaje = CONCAT('Producción ', v_folio, ' finalizada. ',
    v_piezas, ' piezas acreditadas al inventario.');
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_pd_guardar_plantilla` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_pd_guardar_plantilla`(
  IN  p_id_pd       INT,
  IN  p_nombre      VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  IN  p_descripcion TEXT        CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  IN  p_usuario     INT,
  OUT p_id_plant    INT,
  OUT p_ok          TINYINT(1),
  OUT p_mensaje     VARCHAR(500)
)
proc: BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_mensaje = MESSAGE_TEXT;
  END;

  SET p_ok = 0;

  IF NOT EXISTS (SELECT 1 FROM produccion_diaria WHERE id_pd = p_id_pd) THEN
    SET p_mensaje = 'Producción no encontrada.'; LEAVE proc;
  END IF;

  IF p_nombre IS NULL OR TRIM(p_nombre) = '' THEN
    SET p_mensaje = 'El nombre de la plantilla es obligatorio.'; LEAVE proc;
  END IF;

  START TRANSACTION;

  INSERT INTO plantillas_produccion (nombre, descripcion, creado_por, creado_en)
  VALUES (TRIM(p_nombre), NULLIF(TRIM(COALESCE(p_descripcion, '')), ''), p_usuario, NOW());

  SET p_id_plant = LAST_INSERT_ID();

  -- Copiar líneas directamente (id_producto, id_receta, cantidad_piezas)
  INSERT INTO plantillas_produccion_detalle
    (id_plantilla, id_producto, id_receta, cantidad_piezas)
  SELECT p_id_plant, id_producto, id_receta, cantidad_piezas
  FROM   produccion_diaria_detalle
  WHERE  id_pd = p_id_pd;

  COMMIT;

  SET p_ok     = 1;
  SET p_mensaje = CONCAT('Plantilla "', TRIM(p_nombre), '" guardada correctamente.');
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_pd_iniciar` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_pd_iniciar`(
  IN  p_id_pd   INT,
  IN  p_usuario INT,
  OUT p_ok      TINYINT(1),
  OUT p_mensaje VARCHAR(500)
)
proc: BEGIN
  DECLARE v_estado VARCHAR(20);
  DECLARE v_folio  VARCHAR(20);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_mensaje = MESSAGE_TEXT;
  END;

  SET p_ok = 0;

  SELECT estado, folio INTO v_estado, v_folio
  FROM produccion_diaria WHERE id_pd = p_id_pd LIMIT 1;

  IF v_estado IS NULL THEN
    SET p_mensaje = 'Producción no encontrada.'; LEAVE proc;
  END IF;

  IF v_estado <> 'pendiente' THEN
    SET p_mensaje = CONCAT('La producción ', v_folio,
      ' no está pendiente. Estado actual: ', v_estado, '.');
    LEAVE proc;
  END IF;

  -- Verificar que tiene insumos calculados
  IF NOT EXISTS (SELECT 1 FROM produccion_diaria_insumos WHERE id_pd = p_id_pd LIMIT 1) THEN
    SET p_mensaje = 'No hay insumos calculados para esta producción.';
    LEAVE proc;
  END IF;

  START TRANSACTION;

  -- Descontar insumos del almacén y registrar descuento
  UPDATE materias_primas mp
  JOIN   produccion_diaria_insumos pdi ON pdi.id_materia = mp.id_materia
  SET    mp.stock_actual          = mp.stock_actual - pdi.cantidad_requerida,
         mp.actualizado_en        = NOW(),
         pdi.cantidad_descontada  = pdi.cantidad_requerida
  WHERE  pdi.id_pd = p_id_pd;

  -- Cambiar estado
  UPDATE produccion_diaria
  SET    estado             = 'en_proceso',
         fecha_inicio       = NOW(),
         insumos_descontados = 1
  WHERE  id_pd = p_id_pd;

  COMMIT;

  SET p_ok     = 1;
  SET p_mensaje = CONCAT('Producción ', v_folio,
    ' iniciada. Insumos descontados del almacén.');
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_pd_lista` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_pd_lista`(
  IN p_estado    VARCHAR(20)  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci,
  IN p_fecha_ini DATE,
  IN p_fecha_fin DATE,
  IN p_limite    INT,
  IN p_offset    INT
)
BEGIN
  SELECT
    pd.id_pd,
    pd.folio,
    pd.nombre,
    pd.estado,
    pd.total_cajas,
    pd.total_piezas_esperadas,
    pd.alerta_insumos,
    pd.insumos_descontados,
    pd.inventario_acreditado,
    pd.fecha_inicio,
    pd.fecha_fin_real,
    pd.creado_en,
    u_op.nombre_completo AS operario,
    u_cr.nombre_completo AS creado_por_nombre
  FROM  produccion_diaria pd
  LEFT JOIN usuarios u_op ON u_op.id_usuario = pd.operario_id
  LEFT JOIN usuarios u_cr ON u_cr.id_usuario = pd.creado_por
  WHERE (p_estado IS NULL OR pd.estado = CONVERT(p_estado USING utf8mb4) COLLATE utf8mb4_0900_ai_ci)
    AND (p_fecha_ini IS NULL OR DATE(pd.creado_en) >= p_fecha_ini)
    AND (p_fecha_fin IS NULL OR DATE(pd.creado_en) <= p_fecha_fin)
  ORDER BY pd.creado_en DESC
  LIMIT  p_limite OFFSET p_offset;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_pedido_express` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_pedido_express`(
    IN  p_id_cliente     INT,
    IN  p_hora_recogida  TIME,
    IN  p_metodo_pago    VARCHAR(20),
    IN  p_notas          TEXT,
    IN  p_productos_json JSON,
    OUT p_id_pedido      INT,
    OUT p_folio          VARCHAR(15),
    OUT p_error          VARCHAR(255)
)
BEGIN
    DECLARE v_total     DECIMAL(10,2) DEFAULT 0;
    DECLARE v_i         INT DEFAULT 0;
    DECLARE v_n         INT;
    DECLARE v_id_prod   INT;
    DECLARE v_qty       DECIMAL(10,2);
    DECLARE v_precio    DECIMAL(10,2);
    DECLARE v_sub       DECIMAL(12,2);
    DECLARE v_stock     DECIMAL(12,2);
    DECLARE v_nombre    VARCHAR(120);
    DECLARE v_uuid      VARCHAR(36);
    DECLARE v_fecha_rec DATETIME;
    DECLARE v_msg       VARCHAR(255);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
        SET p_id_pedido = NULL;
        SET p_folio     = NULL;
    END;

    SET p_error = NULL;

    
    IF NOT EXISTS (
        SELECT 1 FROM usuarios u
        WHERE u.id_usuario = p_id_cliente
          AND CONVERT(u.estatus USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = 'activo'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El cliente no existe o no está activo.';
    END IF;

    
    IF p_metodo_pago NOT IN ('efectivo','tarjeta','transferencia') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Método de pago inválido.';
    END IF;

    
    SET v_n = JSON_LENGTH(p_productos_json);
    IF v_n IS NULL OR v_n = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El pedido debe tener al menos un producto.';
    END IF;

    
    IF p_hora_recogida < '09:00:00' OR p_hora_recogida > '21:00:00' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La hora de recogida debe estar entre 9:00 y 21:00.';
    END IF;

    SET v_fecha_rec = TIMESTAMP(DATE(NOW()), p_hora_recogida);

    
    WHILE v_i < v_n DO
        SET v_id_prod = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].id')));
        SET v_qty     = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].qty')));
        SET v_precio  = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].precio')));

        SET v_nombre = NULL;
        SELECT nombre INTO v_nombre
          FROM productos
         WHERE id_producto = v_id_prod
           AND CONVERT(estatus USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = 'activo'
         LIMIT 1;

        IF v_nombre IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Uno o más productos no están disponibles.';
        END IF;

        SET v_stock = 0;
        SELECT COALESCE(stock_actual, 0) INTO v_stock
          FROM inventario_pt
         WHERE id_producto = v_id_prod
         LIMIT 1;

        IF v_stock < v_qty THEN
            SET v_msg = CONCAT('Stock insuficiente para "', v_nombre,
                               '". Disponible: ', FLOOR(v_stock), ' pzas.');
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = v_msg;
        END IF;

        SET v_total = v_total + (v_qty * v_precio);
        SET v_i     = v_i + 1;
    END WHILE;

    START TRANSACTION;

        CALL sp_siguiente_folio_pedido(p_folio);
        SET v_uuid = UUID();

        INSERT INTO pedidos (
            uuid_pedido, folio, id_cliente, tipo, estado,
            fecha_recogida, metodo_pago, notas_cliente, total_estimado,
            creado_en, actualizado_en
        ) VALUES (
            v_uuid, p_folio, p_id_cliente, 'simple', 'pendiente',
            v_fecha_rec, p_metodo_pago, p_notas, ROUND(v_total, 2),
            NOW(), NOW()
        );

        SET p_id_pedido = LAST_INSERT_ID();

        SET v_i = 0;
        WHILE v_i < v_n DO
            SET v_id_prod = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].id')));
            SET v_qty     = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].qty')));
            SET v_precio  = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[',v_i,'].precio')));
            SET v_sub     = ROUND(v_qty * v_precio, 2);

            INSERT INTO detalle_pedidos
                (id_pedido, id_producto, cantidad, precio_unitario, subtotal)
            VALUES
                (p_id_pedido, v_id_prod, v_qty, v_precio, v_sub);

            SET v_i = v_i + 1;
        END WHILE;

        INSERT INTO historial_pedidos
            (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
        VALUES
            (p_id_pedido, 'nuevo', 'pendiente',
             CONCAT('Pedido express. Pago: ', p_metodo_pago), p_id_cliente, NOW());

    COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_rechazar_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_rechazar_pedido`(
  IN  p_folio  VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_user   INT,
  IN  p_motivo TEXT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  OUT p_ok     TINYINT(1),
  OUT p_error  VARCHAR(300)
)
sp_main: BEGIN
  DECLARE v_id_pedido  INT;
  DECLARE v_estado     VARCHAR(30);
  DECLARE v_id_cliente INT;
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
  END;
  SET p_ok = 0; SET p_error = NULL;
  SELECT id_pedido, estado, id_cliente
    INTO v_id_pedido, v_estado, v_id_cliente
    FROM pedidos WHERE folio = p_folio LIMIT 1;
  IF v_id_pedido IS NULL THEN
    SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
    LEAVE sp_main;
  END IF;
  IF v_estado NOT IN ('pendiente','aprobado') THEN
    SET p_error = CONCAT('No se puede rechazar un pedido en estado: ', v_estado);
    LEAVE sp_main;
  END IF;
  IF p_motivo IS NULL OR TRIM(p_motivo) = '' THEN
    SET p_error = 'Debes indicar el motivo del rechazo.';
    LEAVE sp_main;
  END IF;
  START TRANSACTION;
  UPDATE pedidos SET estado='rechazado', motivo_rechazo=p_motivo,
         atendido_por=p_user, actualizado_en=NOW()
   WHERE id_pedido = v_id_pedido;
  INSERT INTO historial_pedidos (id_pedido,estado_antes,estado_despues,nota,realizado_por,creado_en)
  VALUES (v_id_pedido,v_estado,'rechazado',p_motivo,p_user,NOW());
  INSERT INTO notificaciones_pedidos (id_pedido,id_usuario,folio,tipo,mensaje,leida,creado_en)
  VALUES (v_id_pedido,v_id_cliente,p_folio,'rechazado',
    CONCAT('Tu pedido ',p_folio,' no pudo ser aceptado. Motivo: ',p_motivo),0,NOW());
  COMMIT;
  SET p_ok = 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_cliente` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_cliente`(
    IN  p_uuid            VARCHAR(36),
    IN  p_nombre_completo VARCHAR(120),
    IN  p_telefono        VARCHAR(20),
    IN  p_username        VARCHAR(60),
    IN  p_password_hash   VARCHAR(255)
)
BEGIN
    -- La restricción UNIQUE de la columna username maneja duplicados (error 1062)
    INSERT INTO usuarios (
        uuid_usuario,
        nombre_completo,
        telefono,
        username,
        password_hash,
        id_rol,
        estatus,
        intentos_fallidos,
        cambio_pwd_req,
        creado_en,
        actualizado_en,
        creado_por
    ) VALUES (
        p_uuid,
        p_nombre_completo,
        NULLIF(p_telefono, ''),
        p_username,
        p_password_hash,
        4,
        'activo',
        0,
        0,
        NOW(),
        NOW(),
        NULL
    );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_merma` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_registrar_merma`(
    IN p_id_materia INT,
    IN p_cantidad DECIMAL(12,4),
    IN p_causa VARCHAR(30),
    IN p_descripcion TEXT,
    IN p_registrado_por INT,
    OUT p_id_merma INT,
    OUT p_error VARCHAR(255)
)
sp_main: BEGIN
    DECLARE v_stock_actual DECIMAL(12,4);
    DECLARE v_nombre_materia VARCHAR(120);
    DECLARE v_unidad VARCHAR(20);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
        SET p_id_merma = NULL;
    END;
    
    SET p_error = NULL;
    SET p_id_merma = NULL;
    
    
    IF p_causa NOT IN ('caducidad', 'quemado_horneado', 'caida_accidente', 'error_produccion', 'rotura_empaque', 'contaminacion', 'otro') THEN
        SET p_error = 'Causa de merma inválida.';
        LEAVE sp_main;
    END IF;
    
    
    IF p_cantidad <= 0 THEN
        SET p_error = 'La cantidad debe ser mayor a cero.';
        LEAVE sp_main;
    END IF;
    
    
    SELECT nombre, unidad_base, stock_actual 
    INTO v_nombre_materia, v_unidad, v_stock_actual
    FROM materias_primas 
    WHERE id_materia = p_id_materia AND estatus = 'activo';
    
    IF v_nombre_materia IS NULL THEN
        SET p_error = 'Materia prima no encontrada o inactiva.';
        LEAVE sp_main;
    END IF;
    
    
    IF v_stock_actual < p_cantidad THEN
        SET p_error = CONCAT('Stock insuficiente. Disponible: ', v_stock_actual, ' ', v_unidad);
        LEAVE sp_main;
    END IF;
    
    START TRANSACTION;
    
    
    INSERT INTO mermas (
        tipo_objeto, id_referencia, cantidad, unidad, 
        causa, descripcion, registrado_por, fecha_merma, creado_en
    ) VALUES (
        'materia_prima', p_id_materia, p_cantidad, v_unidad,
        p_causa, p_descripcion, p_registrado_por, NOW(), NOW()
    );
    
    SET p_id_merma = LAST_INSERT_ID();
    
    
    UPDATE materias_primas 
    SET stock_actual = stock_actual - p_cantidad,
        actualizado_en = NOW()
    WHERE id_materia = p_id_materia;
    
    
    INSERT INTO logs_sistema (tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en)
    VALUES ('ajuste_inv', 'WARNING', p_registrado_por, 'mermas', 'registrar_merma',
            CONCAT('Merma registrada: ', v_nombre_materia, ' - Cantidad: ', p_cantidad, ' ', v_unidad, ' - Causa: ', p_causa), NOW());
    
    COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_merma_producto` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_merma_producto`(
    IN p_id_producto INT,
    IN p_cantidad DECIMAL(12,4),
    IN p_causa VARCHAR(30),
    IN p_descripcion TEXT,
    IN p_registrado_por INT,
    OUT p_id_merma INT,
    OUT p_error VARCHAR(255)
)
sp_main: BEGIN
    DECLARE v_stock_actual DECIMAL(12,4);
    DECLARE v_nombre_producto VARCHAR(120);
    DECLARE v_unidad VARCHAR(20);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
        SET p_id_merma = NULL;
    END;
    
    SET p_error = NULL;
    SET p_id_merma = NULL;
    
    -- Validar causa
    IF p_causa NOT IN ('caducidad', 'quemado_horneado', 'caida_accidente', 'error_produccion', 'rotura_empaque', 'contaminacion', 'otro') THEN
        SET p_error = 'Causa de merma inválida.';
        LEAVE sp_main;
    END IF;
    
    -- Validar cantidad
    IF p_cantidad <= 0 THEN
        SET p_error = 'La cantidad debe ser mayor a cero.';
        LEAVE sp_main;
    END IF;
    
    -- Obtener datos del producto
    SELECT p.nombre, COALESCE(i.stock_actual, 0)
    INTO v_nombre_producto, v_stock_actual
    FROM productos p
    LEFT JOIN inventario_pt i ON i.id_producto = p.id_producto
    WHERE p.id_producto = p_id_producto AND p.estatus = 'activo';
    
    IF v_nombre_producto IS NULL THEN
        SET p_error = 'Producto no encontrado o inactivo.';
        LEAVE sp_main;
    END IF;
    
    -- Validar stock suficiente
    IF v_stock_actual < p_cantidad THEN
        SET p_error = CONCAT('Stock insuficiente. Disponible: ', v_stock_actual, ' piezas');
        LEAVE sp_main;
    END IF;
    
    START TRANSACTION;
    
    -- Insertar registro de merma
    INSERT INTO mermas (
        tipo_objeto, id_referencia, cantidad, unidad, 
        causa, descripcion, registrado_por, fecha_merma, creado_en
    ) VALUES (
        'producto_terminado', p_id_producto, p_cantidad, 'piezas',
        p_causa, p_descripcion, p_registrado_por, NOW(), NOW()
    );
    
    SET p_id_merma = LAST_INSERT_ID();
    
    -- Descontar del inventario de productos terminados
    UPDATE inventario_pt 
    SET stock_actual = stock_actual - p_cantidad,
        ultima_actualizacion = NOW()
    WHERE id_producto = p_id_producto;
    
    -- Registrar en logs
    INSERT INTO logs_sistema (tipo, nivel, id_usuario, modulo, accion, descripcion, creado_en)
    VALUES ('ajuste_inv', 'WARNING', p_registrado_por, 'mermas', 'registrar_merma_producto',
            CONCAT('Merma de producto registrada: ', v_nombre_producto, ' - Cantidad: ', p_cantidad, ' piezas - Causa: ', p_causa), NOW());
    
    COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_produccion` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_registrar_produccion`(
    IN  p_folio_lote       VARCHAR(20),
    IN  p_id_producto      INT,
    IN  p_id_receta        INT,
    IN  p_cantidad_lotes   DECIMAL(10,2),
    IN  p_piezas_esperadas DECIMAL(10,2),
    IN  p_fecha_inicio     DATETIME,
    IN  p_fecha_fin_est    DATETIME,
    IN  p_operario_id      INT,
    IN  p_creado_por       INT,
    IN  p_observaciones    TEXT,
    OUT p_resultado        INT,
    OUT p_mensaje          VARCHAR(500),
    OUT p_id_produccion    INT
)
sp_main: BEGIN

    
    DECLARE v_done             INT DEFAULT FALSE;
    DECLARE v_id_materia       INT;
    DECLARE v_nombre_materia   VARCHAR(120);
    DECLARE v_cant_requerida   DECIMAL(12,4);
    DECLARE v_stock_actual     DECIMAL(12,4);
    DECLARE v_cant_total       DECIMAL(12,4);
    DECLARE v_id_receta_valida INT;
    DECLARE v_folio_existe     INT;

    
    DECLARE cur_validar CURSOR FOR
        SELECT
            dr.id_materia,
            mp.nombre,
            dr.cantidad_requerida,
            mp.stock_actual
        FROM detalle_recetas dr
        JOIN materias_primas mp ON mp.id_materia = dr.id_materia
        WHERE dr.id_receta = p_id_receta
          AND mp.estatus   = 'activo';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_resultado     = 1;
        SET p_mensaje       = 'Error interno. Se realizó ROLLBACK.';
        SET p_id_produccion = 0;
    END;

    
    SET p_resultado     = 1;
    SET p_mensaje       = '';
    SET p_id_produccion = 0;

    
    
    

    
    SELECT COUNT(*) INTO v_folio_existe
    FROM produccion
    WHERE folio_lote = p_folio_lote;

    IF v_folio_existe > 0 THEN
        SET p_mensaje = CONCAT('El folio "', p_folio_lote, '" ya existe.');
        LEAVE sp_main;
    END IF;

    
    SELECT id_receta INTO v_id_receta_valida
    FROM recetas
    WHERE id_receta   = p_id_receta
      AND id_producto = p_id_producto
      AND estatus     = 'activo'
    LIMIT 1;

    IF v_id_receta_valida IS NULL THEN
        SET p_mensaje = 'La receta no corresponde al producto indicado o está inactiva.';
        LEAVE sp_main;
    END IF;

    
    IF NOT EXISTS (
        SELECT 1 FROM detalle_recetas WHERE id_receta = p_id_receta LIMIT 1
    ) THEN
        SET p_mensaje = 'La receta no tiene insumos registrados.';
        LEAVE sp_main;
    END IF;

    
    
    

    OPEN cur_validar;

    loop_validar: LOOP
        FETCH cur_validar INTO
            v_id_materia,
            v_nombre_materia,
            v_cant_requerida,
            v_stock_actual;

        IF v_done THEN
            LEAVE loop_validar;
        END IF;

        SET v_cant_total = v_cant_requerida * p_cantidad_lotes;

        IF v_stock_actual < v_cant_total THEN
            CLOSE cur_validar;
            SET p_mensaje = CONCAT(
                'Stock insuficiente: "', v_nombre_materia, '". ',
                'Requerido: ', ROUND(v_cant_total, 4), ' | ',
                'Disponible: ', ROUND(v_stock_actual, 4)
            );
            LEAVE sp_main;
        END IF;

    END LOOP loop_validar;

    CLOSE cur_validar;

    
    
    
    
    

    START TRANSACTION;

        
        INSERT INTO produccion (
            folio_lote,
            id_producto,
            id_receta,
            cantidad_lotes,
            piezas_esperadas,
            piezas_producidas,
            estado,
            fecha_inicio,
            fecha_fin_estimado,
            fecha_fin_real,
            operario_id,
            observaciones,
            creado_en,
            creado_por
        ) VALUES (
            p_folio_lote,
            p_id_producto,
            p_id_receta,
            p_cantidad_lotes,
            p_piezas_esperadas,
            NULL,
            'pendiente',
            p_fecha_inicio,
            p_fecha_fin_est,
            NULL,
            p_operario_id,
            p_observaciones,
            NOW(),
            p_creado_por
        );

        SET p_id_produccion = LAST_INSERT_ID();

        
        
        INSERT INTO detalle_produccion (
            id_produccion,
            id_materia,
            cantidad_requerida,
            cantidad_descontada
        )
        SELECT
            p_id_produccion,
            dr.id_materia,
            dr.cantidad_requerida * p_cantidad_lotes,
            dr.cantidad_requerida * p_cantidad_lotes
        FROM detalle_recetas dr
        JOIN materias_primas mp ON mp.id_materia = dr.id_materia
        WHERE dr.id_receta = p_id_receta
          AND mp.estatus   = 'activo';

        
        UPDATE materias_primas mp
        JOIN detalle_recetas dr ON dr.id_materia = mp.id_materia
        SET
            mp.stock_actual   = mp.stock_actual - (dr.cantidad_requerida * p_cantidad_lotes),
            mp.actualizado_en = NOW()
        WHERE dr.id_receta = p_id_receta
          AND mp.estatus   = 'activo';

    COMMIT;

    
    
    
    SET p_resultado = 0;
    SET p_mensaje   = CONCAT(
        'Producción registrada. Lote: ', p_folio_lote,
        ' | ID: ', p_id_produccion
    );

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_salida_manual` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_registrar_salida_manual`(
    IN p_folio          VARCHAR(20),
    IN p_id_proveedor   INT,          
    IN p_categoria      VARCHAR(30),
    IN p_descripcion    VARCHAR(255),
    IN p_monto          DECIMAL(12,2),
    IN p_fecha_salida   DATE,
    IN p_registrado_por INT
)
BEGIN
    IF p_monto <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El monto debe ser mayor a cero.';
    END IF;

    IF p_descripcion IS NULL OR TRIM(p_descripcion) = '' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La descripción es obligatoria.';
    END IF;

    IF p_categoria NOT IN ('compra_insumos','servicios_utilities','mantenimiento','otros') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Categoría no válida.';
    END IF;

    INSERT INTO salidas_efectivo (
        folio_salida, id_proveedor, categoria,
        descripcion, monto, fecha_salida,
        estado, registrado_por, creado_en, actualizado_en
    ) VALUES (
        p_folio,
        p_id_proveedor,
        p_categoria,
        p_descripcion,
        p_monto,
        p_fecha_salida,
        'pendiente',
        p_registrado_por,
        NOW(), NOW()
    );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_registrar_venta_caja` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_registrar_venta_caja`(
    IN p_productos_json JSON,
    IN p_metodo_pago VARCHAR(20),
    IN p_efectivo_recibido DECIMAL(10,2),
    IN p_vendedor_id INT,
    OUT p_id_venta INT,
    OUT p_folio_venta VARCHAR(20),
    OUT p_cambio DECIMAL(10,2),
    OUT p_total DECIMAL(10,2)
)
BEGIN
    DECLARE v_next_seq INT;
    DECLARE v_total_venta DECIMAL(10,2) DEFAULT 0;
    DECLARE v_cambio DECIMAL(10,2) DEFAULT 0;
    DECLARE v_idx INT DEFAULT 0;
    DECLARE v_productos_len INT;
    DECLARE v_producto_id INT;
    DECLARE v_cantidad DECIMAL(10,2);
    DECLARE v_precio DECIMAL(10,2);
    DECLARE v_subtotal DECIMAL(10,2);
    DECLARE v_stock_actual DECIMAL(12,2);
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Calcular total de la venta
    SET v_productos_len = JSON_LENGTH(p_productos_json);
    
    WHILE v_idx < v_productos_len DO
        SET v_producto_id = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', v_idx, '].id_producto')));
        SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', v_idx, '].cantidad')));
        SET v_precio = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', v_idx, '].precio')));
        
        -- Validar stock suficiente
        SELECT stock_actual INTO v_stock_actual
        FROM inventario_pt
        WHERE id_producto = v_producto_id;
        
        IF v_stock_actual < v_cantidad THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'Stock insuficiente para uno o más productos';
        END IF;
        
        SET v_subtotal = v_cantidad * v_precio;
        SET v_total_venta = v_total_venta + v_subtotal;
        SET v_idx = v_idx + 1;
    END WHILE;
    
    -- Calcular cambio si es efectivo
    IF p_metodo_pago = 'efectivo' AND p_efectivo_recibido IS NOT NULL THEN
        SET v_cambio = p_efectivo_recibido - v_total_venta;
        IF v_cambio < 0 THEN
            SIGNAL SQLSTATE '45000' 
            SET MESSAGE_TEXT = 'El efectivo recibido es insuficiente';
        END IF;
    END IF;
    
    -- Generar folio de venta
    SELECT COALESCE(COUNT(*), 0) + 1 INTO v_next_seq
    FROM ventas
    WHERE DATE(fecha_venta) = CURDATE();
    
    SET p_folio_venta = CONCAT('VTA-', DATE_FORMAT(NOW(), '%Y%m%d'), '-', LPAD(v_next_seq, 3, '0'));
    SET p_total = v_total_venta;
    SET p_cambio = v_cambio;
    
    -- Insertar cabecera de venta
    INSERT INTO ventas (
        folio_venta, fecha_venta, total, metodo_pago, cambio,
        requiere_ticket, estado, vendedor_id, creado_en
    ) VALUES (
        p_folio_venta, NOW(), v_total_venta, p_metodo_pago, v_cambio,
        1, 'completada', p_vendedor_id, NOW()
    );
    
    SET p_id_venta = LAST_INSERT_ID();
    
    -- Insertar detalles y descontar inventario
    SET v_idx = 0;
    WHILE v_idx < v_productos_len DO
        SET v_producto_id = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', v_idx, '].id_producto')));
        SET v_cantidad = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', v_idx, '].cantidad')));
        SET v_precio = JSON_UNQUOTE(JSON_EXTRACT(p_productos_json, CONCAT('$[', v_idx, '].precio')));
        SET v_subtotal = v_cantidad * v_precio;
        
        -- Insertar detalle
        INSERT INTO detalle_ventas (
            id_venta, id_producto, cantidad, precio_unitario, 
            descuento_pct, subtotal
        ) VALUES (
            p_id_venta, v_producto_id, v_cantidad, v_precio, 0, v_subtotal
        );
        
        -- Descontar inventario
        UPDATE inventario_pt 
        SET stock_actual = stock_actual - v_cantidad,
            ultima_actualizacion = NOW()
        WHERE id_producto = v_producto_id;
        
        SET v_idx = v_idx + 1;
    END WHILE;
    
    -- Registrar en logs
    INSERT INTO logs_sistema (
        tipo, nivel, id_usuario, modulo, accion, descripcion,
        referencia_id, referencia_tipo, creado_en
    ) VALUES (
        'venta', 'INFO', p_vendedor_id, 'ventas', 'venta_caja',
        CONCAT('Venta en caja registrada: ', p_folio_venta, ' | Total: $', v_total_venta),
        p_id_venta, 'venta', NOW()
    );
    
    COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_reporte_costo_utilidad` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_reporte_costo_utilidad`(
    IN p_buscar    VARCHAR(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
    IN p_orden     VARCHAR(30),
    IN p_util_min  DECIMAL(12,4),
    IN p_util_max  DECIMAL(12,4)
)
BEGIN
    
    DROP TEMPORARY TABLE IF EXISTS tmp_costo_receta;

    CREATE TEMPORARY TABLE tmp_costo_receta AS
    SELECT
        dr.id_receta,
        ROUND(
            SUM(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0)),
            4
        ) AS costo_total_lote
    FROM detalle_recetas dr
    LEFT JOIN v_costo_promedio_materia cpm ON cpm.id_materia = dr.id_materia
    GROUP BY dr.id_receta;

    
    DROP TEMPORARY TABLE IF EXISTS tmp_precio_real;
    CREATE TEMPORARY TABLE tmp_precio_real AS
    SELECT dv.id_producto, ROUND(AVG(dv.precio_unitario), 2) AS precio_real
    FROM detalle_ventas dv
    INNER JOIN ventas v ON v.id_venta = dv.id_venta
    WHERE v.estado = 'completada'
      AND DATE(v.fecha_venta) >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    GROUP BY dv.id_producto;

    
    DROP TEMPORARY TABLE IF EXISTS tmp_resultado_cu;

    CREATE TEMPORARY TABLE tmp_resultado_cu AS
    SELECT
        p.id_producto,
        p.nombre                                                    AS nombre_producto,
        COALESCE(pvr.precio_real, p.precio_venta)                  AS precio_venta,
        r.id_receta,
        r.nombre                                                    AS nombre_receta,
        r.rendimiento,
        r.unidad_rendimiento,
        ROUND(
            COALESCE(tcr.costo_total_lote, 0) / r.rendimiento,
            4
        )                                                           AS costo_unitario,
        ROUND(
            COALESCE(pvr.precio_real, p.precio_venta)
                - (COALESCE(tcr.costo_total_lote, 0) / r.rendimiento),
            4
        )                                                           AS utilidad_unitaria,
        CASE
            WHEN COALESCE(pvr.precio_real, p.precio_venta) > 0 THEN
                ROUND(
                    (COALESCE(pvr.precio_real, p.precio_venta)
                        - (COALESCE(tcr.costo_total_lote, 0) / r.rendimiento))
                    / COALESCE(pvr.precio_real, p.precio_venta) * 100,
                    2
                )
            ELSE 0
        END                                                         AS margen_pct
    FROM productos p
    INNER JOIN recetas r
           ON  r.id_producto = p.id_producto
           AND r.estatus     = 'activo'
    LEFT JOIN tmp_costo_receta tcr ON tcr.id_receta = r.id_receta
    LEFT JOIN tmp_precio_real  pvr ON pvr.id_producto = p.id_producto
    WHERE p.estatus = 'activo'
      AND (
          p_buscar IS NULL
          OR p_buscar = ''
          OR p.nombre LIKE CONCAT('%', p_buscar COLLATE utf8mb4_unicode_ci, '%')
      );

    
    SELECT *
    FROM tmp_resultado_cu
    WHERE (p_util_min IS NULL OR utilidad_unitaria >= p_util_min)
      AND (p_util_max IS NULL OR utilidad_unitaria <= p_util_max)
    ORDER BY
        CASE WHEN p_orden = 'margen_asc'  THEN margen_pct     END ASC,
        CASE WHEN p_orden = 'margen_desc' THEN margen_pct     END DESC,
        CASE WHEN p_orden = 'costo_asc'   THEN costo_unitario END ASC,
        CASE WHEN p_orden = 'costo_desc'  THEN costo_unitario END DESC,
        nombre_producto ASC;

    
    DROP TEMPORARY TABLE IF EXISTS tmp_resultado_cu;
    DROP TEMPORARY TABLE IF EXISTS tmp_costo_receta;
    DROP TEMPORARY TABLE IF EXISTS tmp_precio_real;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_reporte_utilidad_ventas` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_reporte_utilidad_ventas`(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin    DATE
)
BEGIN

    
    DROP TEMPORARY TABLE IF EXISTS tmp_uv_costo_lote;
    CREATE TEMPORARY TABLE tmp_uv_costo_lote AS
    SELECT
        dr.id_receta,
        ROUND(
            SUM(dr.cantidad_requerida * COALESCE(cpm.costo_base_promedio, 0)),
        4) AS costo_total_lote
    FROM detalle_recetas dr
    LEFT JOIN v_costo_promedio_materia cpm ON cpm.id_materia = dr.id_materia
    GROUP BY dr.id_receta;

    
    
    DROP TEMPORARY TABLE IF EXISTS tmp_uv_costo_unit;
    CREATE TEMPORARY TABLE tmp_uv_costo_unit AS
    SELECT
        r.id_producto,
        ROUND(
            COALESCE(tcl.costo_total_lote, 0) / NULLIF(r.rendimiento, 0),
        4) AS costo_unitario
    FROM recetas r
    LEFT JOIN tmp_uv_costo_lote tcl ON tcl.id_receta = r.id_receta
    WHERE r.estatus = 'activo'
    ORDER BY r.id_producto, (r.id_tamanio IS NULL) DESC, r.id_receta ASC
    LIMIT 18446744073709551615;   

    
    DROP TEMPORARY TABLE IF EXISTS tmp_uv_costo_final;
    CREATE TEMPORARY TABLE tmp_uv_costo_final AS
    SELECT id_producto, MIN(costo_unitario) AS costo_unitario
    FROM tmp_uv_costo_unit
    GROUP BY id_producto;

    
    SELECT
        COUNT(DISTINCT v.id_venta)                                              AS total_ventas,
        COUNT(DISTINCT dv.id_producto)                                          AS total_productos,
        ROUND(SUM(dv.subtotal), 2)                                              AS total_ingresos,
        ROUND(SUM(dv.cantidad * COALESCE(cu.costo_unitario, 0)), 2)            AS total_costo,
        ROUND(
            SUM(dv.subtotal)
            - SUM(dv.cantidad * COALESCE(cu.costo_unitario, 0)),
        2)                                                                      AS total_utilidad,
        ROUND(
            (1 - SUM(dv.cantidad * COALESCE(cu.costo_unitario, 0))
                   / NULLIF(SUM(dv.subtotal), 0)) * 100,
        2)                                                                      AS margen_prom
    FROM ventas v
    INNER JOIN detalle_ventas dv ON dv.id_venta    = v.id_venta
    LEFT  JOIN tmp_uv_costo_final cu ON cu.id_producto = dv.id_producto
    WHERE DATE(v.fecha_venta) BETWEEN p_fecha_inicio AND p_fecha_fin
      AND v.estado = 'completada';

    
    SELECT
        p.id_producto,
        p.nombre                                                                AS nombre_producto,
        ROUND(SUM(dv.cantidad), 2)                                             AS total_piezas,
        ROUND(AVG(dv.precio_unitario), 2)                                      AS precio_prom_venta,
        ROUND(MAX(COALESCE(cu.costo_unitario, 0)), 4)                          AS costo_unitario,
        ROUND(AVG(dv.precio_unitario) - MAX(COALESCE(cu.costo_unitario, 0)), 4) AS utilidad_unitaria,
        ROUND(
            CASE WHEN AVG(dv.precio_unitario) > 0 THEN
                (AVG(dv.precio_unitario) - MAX(COALESCE(cu.costo_unitario, 0)))
                / AVG(dv.precio_unitario) * 100
            ELSE 0 END,
        2)                                                                      AS margen_pct,
        ROUND(SUM(dv.subtotal - dv.cantidad * COALESCE(cu.costo_unitario, 0)), 2) AS utilidad_total,
        ROUND(SUM(dv.subtotal), 2)                                             AS ingresos_total
    FROM ventas v
    INNER JOIN detalle_ventas dv ON dv.id_venta    = v.id_venta
    INNER JOIN productos       p  ON p.id_producto  = dv.id_producto
    LEFT  JOIN tmp_uv_costo_final cu ON cu.id_producto = dv.id_producto
    WHERE DATE(v.fecha_venta) BETWEEN p_fecha_inicio AND p_fecha_fin
      AND v.estado = 'completada'
    GROUP BY p.id_producto, p.nombre
    ORDER BY utilidad_total DESC;

    
    SELECT
        v.id_venta,
        v.folio_venta,
        DATE(v.fecha_venta)                                                     AS fecha_venta,
        TIME(v.fecha_venta)                                                     AS hora_venta,
        p.nombre                                                                AS nombre_producto,
        ROUND(dv.cantidad, 2)                                                  AS cantidad,
        ROUND(dv.precio_unitario, 2)                                           AS precio_venta,
        ROUND(COALESCE(cu.costo_unitario, 0), 4)                               AS costo_unitario,
        ROUND(dv.precio_unitario - COALESCE(cu.costo_unitario, 0), 4)         AS utilidad_unitaria,
        ROUND(dv.subtotal - dv.cantidad * COALESCE(cu.costo_unitario, 0), 2)  AS utilidad_total,
        ROUND(dv.subtotal, 2)                                                  AS ingreso_total
    FROM ventas v
    INNER JOIN detalle_ventas dv ON dv.id_venta    = v.id_venta
    INNER JOIN productos       p  ON p.id_producto  = dv.id_producto
    LEFT  JOIN tmp_uv_costo_final cu ON cu.id_producto = dv.id_producto
    WHERE DATE(v.fecha_venta) BETWEEN p_fecha_inicio AND p_fecha_fin
      AND v.estado = 'completada'
    ORDER BY v.fecha_venta DESC, v.folio_venta, p.nombre;

    
    DROP TEMPORARY TABLE IF EXISTS tmp_uv_costo_lote;
    DROP TEMPORARY TABLE IF EXISTS tmp_uv_costo_unit;
    DROP TEMPORARY TABLE IF EXISTS tmp_uv_costo_final;

END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_siguiente_folio_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_siguiente_folio_pedido`(OUT p_folio VARCHAR(15))
BEGIN
    DECLARE v_ultimo VARCHAR(15);
    DECLARE v_num    INT;

    SELECT folio INTO v_ultimo
    FROM pedidos
    ORDER BY id_pedido DESC
    LIMIT 1
    FOR UPDATE;          

    IF v_ultimo IS NULL THEN
        SET v_num = 1;
    ELSE
        SET v_num = CAST(SUBSTRING(v_ultimo, 5) AS UNSIGNED) + 1;
    END IF;

    SET p_folio = CONCAT('PED-', LPAD(v_num, 4, '0'));
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_terminar_produccion_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_terminar_produccion_pedido`(
  IN  p_folio VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  IN  p_user  INT,
  OUT p_ok    TINYINT(1),
  OUT p_error VARCHAR(300)
)
sp_main: BEGIN
  DECLARE v_id_pedido  INT;
  DECLARE v_estado     VARCHAR(30);
  DECLARE v_id_cliente INT;
  DECLARE v_folio_txt  VARCHAR(30);

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    SET p_ok = 0;
    GET DIAGNOSTICS CONDITION 1 p_error = MESSAGE_TEXT;
  END;

  SET p_ok = 0; SET p_error = NULL;

  
  SET v_folio_txt = CONVERT(p_folio USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;

  SELECT id_pedido, estado, id_cliente
    INTO v_id_pedido, v_estado, v_id_cliente
    FROM pedidos WHERE folio = p_folio LIMIT 1;

  IF v_id_pedido IS NULL THEN
    SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
    LEAVE sp_main;
  END IF;

  IF v_estado != 'en_produccion' THEN
    SET p_error = CONCAT('Solo se pueden terminar pedidos en producción. Estado actual: ', v_estado);
    LEAVE sp_main;
  END IF;

  START TRANSACTION;

  UPDATE pedidos
     SET estado = 'listo', actualizado_en = NOW()
   WHERE id_pedido = v_id_pedido;

  
  UPDATE produccion
     SET estado             = 'finalizado',
         fecha_fin_real     = NOW(),
         piezas_producidas  = piezas_esperadas
   WHERE observaciones = CONCAT('Pedido ', v_folio_txt)
     AND estado        = 'en_proceso';

  INSERT INTO historial_pedidos (id_pedido, estado_antes, estado_despues, nota, realizado_por, creado_en)
  VALUES (v_id_pedido, 'en_produccion', 'listo',
          'Producción terminada. Pedido listo para recoger.', p_user, NOW());

  INSERT INTO notificaciones_pedidos (id_pedido, id_usuario, folio, tipo, mensaje, leida, creado_en)
  VALUES (v_id_pedido, v_id_cliente, p_folio, 'listo',
          CONCAT('🎉 ¡Tu pedido ', p_folio, ' está listo! Pasa a recogerlo cuando quieras.'),
          0, NOW());

  INSERT INTO logs_sistema (tipo, nivel, id_usuario, modulo, accion, descripcion,
    referencia_id, referencia_tipo, creado_en)
  VALUES ('produccion', 'INFO', p_user, 'Pedidos', 'terminar_produccion',
    CONCAT('Pedido ', p_folio, ' terminado → listo. Cliente notificado.'),
    v_id_pedido, 'pedidos', NOW());

  COMMIT;
  SET p_ok = 1;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_toggle_materia_prima` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_toggle_materia_prima`(
    IN  p_id_materia    INT,
    IN  p_ejecutado_por INT
)
BEGIN
    DECLARE v_estatus_actual VARCHAR(10);
    DECLARE v_nombre         VARCHAR(120);
    DECLARE v_nuevo_estatus  VARCHAR(10);

    
    SELECT estatus, nombre
    INTO   v_estatus_actual, v_nombre
    FROM   materias_primas
    WHERE  id_materia = p_id_materia;

    IF v_estatus_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La materia prima no existe.';
    END IF;

    SET v_nuevo_estatus = IF(v_estatus_actual = 'activo', 'inactivo', 'activo');

    UPDATE materias_primas
    SET estatus        = v_nuevo_estatus,
        actualizado_en = NOW()
    WHERE id_materia = p_id_materia;

    
    INSERT INTO logs_sistema (
        tipo,         nivel,  id_usuario,     modulo,
        accion,       descripcion,            creado_en
    ) VALUES (
        'ajuste_inv', 'INFO', p_ejecutado_por, 'materias_primas',
        'TOGGLE_ESTATUS',
        CONCAT('Materia prima "', v_nombre, '" cambiada a ', v_nuevo_estatus),
        NOW()
    );

    
    SELECT v_nuevo_estatus AS nuevo_estatus,
           v_nombre        AS nombre;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_toggle_producto` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_toggle_producto`(
    IN  p_id_producto   INT,
    IN  p_ejecutado_por INT
)
BEGIN
    DECLARE v_estatus_actual VARCHAR(10);
    DECLARE v_nombre         VARCHAR(120);
    DECLARE v_nuevo_estatus  VARCHAR(10);

    
    SELECT estatus, nombre
    INTO   v_estatus_actual, v_nombre
    FROM   productos
    WHERE  id_producto = p_id_producto;

    IF v_estatus_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El producto no existe.';
    END IF;

    SET v_nuevo_estatus = IF(v_estatus_actual = 'activo', 'inactivo', 'activo');

    UPDATE productos
    SET estatus        = v_nuevo_estatus,
        actualizado_en = NOW()
    WHERE id_producto = p_id_producto;

    
    INSERT INTO logs_sistema (
        tipo,    nivel,  id_usuario,     modulo,
        accion,  descripcion,            creado_en
    ) VALUES (
        'venta', 'INFO', p_ejecutado_por, 'productos',
        'TOGGLE_ESTATUS',
        CONCAT('Producto "', v_nombre, '" cambiado a ', v_nuevo_estatus),
        NOW()
    );

    SELECT v_nuevo_estatus AS nuevo_estatus,
           v_nombre        AS nombre;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_toggle_proveedor` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_toggle_proveedor`(
    IN  p_id_proveedor  INT,
    IN  p_ejecutado_por INT
)
BEGIN
    DECLARE v_estatus_actual VARCHAR(10);
    DECLARE v_nombre         VARCHAR(150);
    DECLARE v_nuevo_estatus  VARCHAR(10);

    
    SELECT estatus, nombre
    INTO   v_estatus_actual, v_nombre
    FROM   proveedores
    WHERE  id_proveedor = p_id_proveedor;

    IF v_estatus_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'El proveedor no existe.';
    END IF;

    SET v_nuevo_estatus = IF(v_estatus_actual = 'activo', 'inactivo', 'activo');

    UPDATE proveedores
    SET estatus        = v_nuevo_estatus,
        actualizado_en = NOW()
    WHERE id_proveedor = p_id_proveedor;

    
    INSERT INTO logs_sistema (
        tipo,    nivel,  id_usuario,     modulo,
        accion,  descripcion,            creado_en
    ) VALUES (
        'compra', 'INFO', p_ejecutado_por, 'proveedores',
        'TOGGLE_ESTATUS',
        CONCAT('Proveedor "', v_nombre, '" cambiado a ', v_nuevo_estatus),
        NOW()
    );

    
    SELECT v_nuevo_estatus AS nuevo_estatus,
           v_nombre        AS nombre;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_toggle_receta` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_toggle_receta`(
    IN  p_id_receta      INT,
    IN  p_ejecutado_por  INT
)
BEGIN
    DECLARE v_estatus_actual VARCHAR(10);
    DECLARE v_nombre         VARCHAR(120);
    DECLARE v_nuevo_estatus  VARCHAR(10);

    
    SELECT estatus, nombre
    INTO   v_estatus_actual, v_nombre
    FROM   recetas
    WHERE  id_receta = p_id_receta;

    IF v_estatus_actual IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La receta no existe.';
    END IF;

    SET v_nuevo_estatus = IF(v_estatus_actual = 'activo', 'inactivo', 'activo');

    UPDATE recetas
    SET estatus        = v_nuevo_estatus,
        actualizado_en = NOW()
    WHERE id_receta = p_id_receta;

    
    INSERT INTO logs_sistema (
        tipo,         nivel,  id_usuario,     modulo,
        accion,       descripcion,            creado_en
    ) VALUES (
        'produccion', 'INFO', p_ejecutado_por, 'recetas',
        'TOGGLE_ESTATUS',
        CONCAT('Receta "', v_nombre, '" cambiada a ', v_nuevo_estatus),
        NOW()
    );

    
    SELECT v_nuevo_estatus AS nuevo_estatus,
           v_nombre        AS nombre;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_verificar_insumos_pedido` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `sp_verificar_insumos_pedido`(
  IN  p_folio VARCHAR(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  OUT p_ok    TINYINT(1),
  OUT p_error VARCHAR(300)
)
sp_main: BEGIN
  DECLARE v_id_pedido  INT;
  DECLARE v_estado     VARCHAR(30);
  DECLARE v_id_tamanio INT;
  SET p_ok = 0; SET p_error = NULL;
  SELECT id_pedido, estado, id_tamanio
    INTO v_id_pedido, v_estado, v_id_tamanio
    FROM pedidos WHERE folio = p_folio LIMIT 1;
  IF v_id_pedido IS NULL THEN
    SET p_error = CONCAT('Pedido ', p_folio, ' no encontrado.');
    LEAVE sp_main;
  END IF;
  SET p_ok = 1;
  SELECT
    mp.id_materia, mp.nombre AS nombre_materia,
    mp.unidad_base, mp.categoria,
    ROUND(SUM((dp.cantidad / r.rendimiento) * dr.cantidad_requerida), 4) AS cantidad_requerida,
    mp.stock_actual, mp.stock_minimo,
    CASE WHEN mp.stock_actual >= ROUND(SUM((dp.cantidad / r.rendimiento) * dr.cantidad_requerida), 4)
         THEN 1 ELSE 0 END AS stock_suficiente,
    LEAST(100, ROUND(mp.stock_actual /
      NULLIF(ROUND(SUM((dp.cantidad / r.rendimiento) * dr.cantidad_requerida), 4), 0) * 100, 1))
      AS pct_disponible
  FROM detalle_pedidos dp
  JOIN recetas r ON r.id_producto = dp.id_producto AND r.estatus = 'activo'
               AND ((v_id_tamanio IS NOT NULL AND r.id_tamanio = v_id_tamanio)
                    OR (v_id_tamanio IS NULL AND r.id_tamanio IS NULL))
  JOIN detalle_recetas dr ON dr.id_receta = r.id_receta
  JOIN materias_primas mp ON mp.id_materia = dr.id_materia
  WHERE dp.id_pedido = v_id_pedido
  GROUP BY mp.id_materia, mp.nombre, mp.unidad_base, mp.categoria, mp.stock_actual, mp.stock_minimo
  ORDER BY mp.nombre;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `_fix_pedidos_tipo` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`dm_restore`@`localhost` PROCEDURE `_fix_pedidos_tipo`()
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME   = 'pedidos'
      AND COLUMN_NAME  = 'tipo'
  ) THEN
    ALTER TABLE `pedidos`
      ADD COLUMN `tipo` ENUM('simple','mixta','triple') NOT NULL DEFAULT 'simple'
          AFTER `id_tamanio`;
  END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `v_caja_pedido`
--

/*!50001 DROP VIEW IF EXISTS `v_caja_pedido`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_caja_pedido` AS select `p`.`id_pedido` AS `id_pedido`,(`p`.`tipo` collate utf8mb4_unicode_ci) AS `tipo`,(`t`.`nombre` collate utf8mb4_unicode_ci) AS `tamanio`,(`t`.`nombre` collate utf8mb4_unicode_ci) AS `nombre_caja`,`t`.`capacidad` AS `capacidad`,`p`.`total_estimado` AS `precio_venta` from (`pedidos` `p` join `tamanios_charola` `t` on((`t`.`id_tamanio` = `p`.`id_tamanio`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_cajas_detalle`
--

/*!50001 DROP VIEW IF EXISTS `v_cajas_detalle`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_cajas_detalle` AS select `c`.`id_caja` AS `id_caja`,`c`.`nombre` AS `nombre_caja`,`c`.`tipo` AS `tipo`,`t`.`nombre` AS `tamanio`,`t`.`capacidad` AS `capacidad`,`c`.`precio_venta` AS `precio_venta`,`c`.`estatus` AS `estatus`,group_concat(`p`.`nombre` order by `cp`.`cantidad` DESC separator ' + ') AS `productos`,sum(`cp`.`cantidad`) AS `total_piezas` from (((`cajas` `c` join `tamanios_charola` `t` on((`t`.`id_tamanio` = `c`.`id_tamanio`))) join `caja_productos` `cp` on((`cp`.`id_caja` = `c`.`id_caja`))) join `productos` `p` on((`p`.`id_producto` = `cp`.`id_producto`))) group by `c`.`id_caja`,`c`.`nombre`,`c`.`tipo`,`t`.`nombre`,`t`.`capacidad`,`c`.`precio_venta`,`c`.`estatus` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_conteo_pedidos_por_estado`
--

/*!50001 DROP VIEW IF EXISTS `v_conteo_pedidos_por_estado`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_conteo_pedidos_por_estado` AS select (convert(`pedidos`.`estado` using utf8mb4) collate utf8mb4_unicode_ci) AS `estado`,count(0) AS `total` from `pedidos` where (`pedidos`.`estado` in ('pendiente','aprobado','listo','entregado','rechazado')) group by `pedidos`.`estado` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_costo_promedio_materia`
--

/*!50001 DROP VIEW IF EXISTS `v_costo_promedio_materia`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_costo_promedio_materia` AS select `ult`.`id_materia` AS `id_materia`,coalesce(`cpp`.`costo_base_12m`,`ult`.`costo_base`) AS `costo_base_promedio` from (`v_ultimo_costo_materia` `ult` left join (select `dc`.`id_materia` AS `id_materia`,round((sum((`dc`.`cantidad_base` * (`dc`.`costo_unitario` / `dc`.`factor_conversion`))) / nullif(sum(`dc`.`cantidad_base`),0)),6) AS `costo_base_12m` from (`detalle_compras` `dc` join `compras` `c` on((`c`.`id_compra` = `dc`.`id_compra`))) where ((`c`.`estatus` = 'finalizado') and (`dc`.`factor_conversion` > 0) and (`dc`.`cantidad_base` > 0) and (`c`.`fecha_compra` >= (curdate() - interval 12 month))) group by `dc`.`id_materia`) `cpp` on((`cpp`.`id_materia` = `ult`.`id_materia`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_detalle_pedido`
--

/*!50001 DROP VIEW IF EXISTS `v_detalle_pedido`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_detalle_pedido` AS select `dp`.`id_pedido` AS `id_pedido`,`pr`.`nombre` AS `producto_nombre`,`pr`.`descripcion` AS `producto_descripcion`,`dp`.`cantidad` AS `cantidad`,`dp`.`precio_unitario` AS `precio_unitario`,`dp`.`subtotal` AS `subtotal` from (`detalle_pedidos` `dp` join `productos` `pr` on((`pr`.`id_producto` = `dp`.`id_producto`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_historial_pedido`
--

/*!50001 DROP VIEW IF EXISTS `v_historial_pedido`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_historial_pedido` AS select `h`.`id_pedido` AS `id_pedido`,`h`.`estado_antes` AS `estado_antes`,`h`.`estado_despues` AS `estado_despues`,`h`.`nota` AS `nota`,`h`.`creado_en` AS `creado_en`,`u`.`nombre_completo` AS `usuario_nombre` from (`historial_pedidos` `h` left join `usuarios` `u` on((`u`.`id_usuario` = `h`.`realizado_por`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_notificaciones_cliente`
--

/*!50001 DROP VIEW IF EXISTS `v_notificaciones_cliente`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_notificaciones_cliente` AS select `notificaciones_pedidos`.`id_notif` AS `id_notif`,`notificaciones_pedidos`.`id_pedido` AS `id_pedido`,`notificaciones_pedidos`.`id_usuario` AS `id_usuario`,`notificaciones_pedidos`.`folio` AS `folio`,`notificaciones_pedidos`.`mensaje` AS `mensaje`,`notificaciones_pedidos`.`leida` AS `leida`,`notificaciones_pedidos`.`creado_en` AS `creado_en` from `notificaciones_pedidos` order by `notificaciones_pedidos`.`creado_en` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_pedido_detalle_completo`
--

/*!50001 DROP VIEW IF EXISTS `v_pedido_detalle_completo`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_pedido_detalle_completo` AS select `dp`.`id_pedido` AS `id_pedido`,`dp`.`id_detalle` AS `id_detalle`,(convert(`pr`.`nombre` using utf8mb4) collate utf8mb4_0900_ai_ci) AS `producto_nombre`,(convert(`pr`.`descripcion` using utf8mb4) collate utf8mb4_0900_ai_ci) AS `producto_descripcion`,`dp`.`cantidad` AS `cantidad`,`dp`.`precio_unitario` AS `precio_unitario`,`dp`.`subtotal` AS `subtotal` from (`detalle_pedidos` `dp` join `productos` `pr` on((`pr`.`id_producto` = `dp`.`id_producto`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_pedidos_resumen`
--

/*!50001 DROP VIEW IF EXISTS `v_pedidos_resumen`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_pedidos_resumen` AS select `p`.`id_pedido` AS `id_pedido`,`p`.`folio` AS `folio`,`p`.`estado` AS `estado`,`p`.`fecha_recogida` AS `fecha_recogida`,`p`.`total_estimado` AS `total_estimado`,`p`.`motivo_rechazo` AS `motivo_rechazo`,`p`.`creado_en` AS `creado_en`,`p`.`actualizado_en` AS `actualizado_en`,`p`.`id_cliente` AS `id_cliente`,`p`.`tipo` AS `tipo_caja`,(`t`.`nombre` collate utf8mb4_unicode_ci) AS `tamanio_nombre`,`t`.`capacidad` AS `capacidad`,`u`.`id_usuario` AS `id_usuario`,`u`.`nombre_completo` AS `cliente_nombre`,`u`.`username` AS `cliente_username`,count(`dp`.`id_detalle`) AS `num_productos`,ifnull(sum(`dp`.`cantidad`),0) AS `total_piezas`,`a`.`nombre_completo` AS `atendido_por_nombre` from ((((`pedidos` `p` join `usuarios` `u` on((`u`.`id_usuario` = `p`.`id_cliente`))) left join `tamanios_charola` `t` on((`t`.`id_tamanio` = `p`.`id_tamanio`))) left join `detalle_pedidos` `dp` on((`dp`.`id_pedido` = `p`.`id_pedido`))) left join `usuarios` `a` on((`a`.`id_usuario` = `p`.`atendido_por`))) group by `p`.`id_pedido`,`p`.`folio`,`p`.`estado`,`p`.`fecha_recogida`,`p`.`total_estimado`,`p`.`motivo_rechazo`,`p`.`creado_en`,`p`.`actualizado_en`,`p`.`id_cliente`,`p`.`tipo`,`t`.`nombre`,`t`.`capacidad`,`u`.`id_usuario`,`u`.`nombre_completo`,`u`.`username`,`a`.`nombre_completo` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

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
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_recetas_explosion` AS select `pt`.`nombre` AS `producto`,`r`.`nombre` AS `receta`,`r`.`rendimiento` AS `rendimiento`,`r`.`unidad_rendimiento` AS `unidad_rendimiento`,`mp`.`nombre` AS `insumo`,`dr`.`cantidad_requerida` AS `cantidad_requerida`,`mp`.`unidad_base` AS `unidad_base`,`dr`.`orden` AS `orden` from (((`detalle_recetas` `dr` join `recetas` `r` on((`r`.`id_receta` = `dr`.`id_receta`))) join `productos_terminados` `pt` on((`pt`.`id_producto` = `r`.`id_producto`))) join `materias_primas` `mp` on((`mp`.`id_materia` = `dr`.`id_materia`))) order by `pt`.`nombre`,`r`.`rendimiento`,`dr`.`orden` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_recetas_por_tamanio`
--

/*!50001 DROP VIEW IF EXISTS `v_recetas_por_tamanio`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_recetas_por_tamanio` AS select `r`.`id_receta` AS `id_receta`,`r`.`nombre` AS `nombre_receta`,`p`.`nombre` AS `nombre_producto`,`t`.`nombre` AS `tamanio`,`t`.`capacidad` AS `piezas`,`r`.`rendimiento` AS `rendimiento`,`mp`.`nombre` AS `ingrediente`,`dr`.`cantidad_requerida` AS `cantidad_requerida`,`mp`.`unidad_base` AS `unidad` from ((((`recetas` `r` join `tamanios_charola` `t` on((`t`.`id_tamanio` = `r`.`id_tamanio`))) join `productos` `p` on((`p`.`id_producto` = `r`.`id_producto`))) join `detalle_recetas` `dr` on((`dr`.`id_receta` = `r`.`id_receta`))) join `materias_primas` `mp` on((`mp`.`id_materia` = `dr`.`id_materia`))) where (`r`.`estatus` = 'activo') order by `p`.`nombre`,`t`.`capacidad`,`dr`.`orden` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `v_ultimo_costo_materia`
--

/*!50001 DROP VIEW IF EXISTS `v_ultimo_costo_materia`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `v_ultimo_costo_materia` AS select `dc`.`id_materia` AS `id_materia`,`dc`.`costo_unitario` AS `costo_por_unidad_base`,`dc`.`unidad_compra` AS `unidad_compra`,`dc`.`factor_conversion` AS `factor_conversion`,round((`dc`.`costo_unitario` / `dc`.`factor_conversion`),6) AS `costo_base` from (`detalle_compras` `dc` join (select `dc2`.`id_materia` AS `id_materia`,max(`dc2`.`id_compra`) AS `max_compra` from `detalle_compras` `dc2` group by `dc2`.`id_materia`) `ult` on(((`dc`.`id_materia` = `ult`.`id_materia`) and (`dc`.`id_compra` = `ult`.`max_compra`)))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_compras`
--

/*!50001 DROP VIEW IF EXISTS `vw_compras`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_compras` AS select `c`.`id_compra` AS `id_compra`,`c`.`folio` AS `folio`,`c`.`folio_factura` AS `folio_factura`,`c`.`id_proveedor` AS `id_proveedor`,`p`.`nombre` AS `nombre_proveedor`,`c`.`fecha_compra` AS `fecha_compra`,`c`.`total` AS `total`,`c`.`estatus` AS `estatus`,`c`.`motivo_cancelacion` AS `motivo_cancelacion`,`c`.`observaciones` AS `observaciones`,`c`.`creado_en` AS `creado_en`,`c`.`creado_por` AS `creado_por`,(select `se`.`estado` from `salidas_efectivo` `se` where (`se`.`id_compra` = `c`.`id_compra`) order by `se`.`id_salida` desc limit 1) AS `estatus_pago` from (`compras` `c` join `proveedores` `p` on((`c`.`id_proveedor` = `p`.`id_proveedor`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_corte_ventas_dia`
--

/*!50001 DROP VIEW IF EXISTS `vw_corte_ventas_dia`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_corte_ventas_dia` AS select ('caja' collate utf8mb4_0900_ai_ci) AS `origen`,`v`.`id_venta` AS `id_transaccion`,`v`.`folio_venta` AS `folio`,cast(`v`.`fecha_venta` as date) AS `fecha`,cast(`v`.`fecha_venta` as time) AS `hora`,`v`.`total` AS `total`,(convert(`v`.`metodo_pago` using utf8mb4) collate utf8mb4_0900_ai_ci) AS `metodo_pago`,(convert(`v`.`estado` using utf8mb4) collate utf8mb4_0900_ai_ci) AS `estado`,`u`.`nombre_completo` AS `vendedor`,coalesce(sum(`dv`.`cantidad`),0) AS `total_piezas` from ((`ventas` `v` join `usuarios` `u` on((`u`.`id_usuario` = `v`.`vendedor_id`))) left join `detalle_ventas` `dv` on((`dv`.`id_venta` = `v`.`id_venta`))) where (`v`.`estado` in ('completada','cancelada')) group by `v`.`id_venta`,`v`.`folio_venta`,`v`.`fecha_venta`,`v`.`total`,`v`.`metodo_pago`,`v`.`estado`,`u`.`nombre_completo` union all select ('pedido_web' collate utf8mb4_0900_ai_ci) AS `origen`,`p`.`id_pedido` AS `id_transaccion`,(convert(`p`.`folio` using utf8mb4) collate utf8mb4_0900_ai_ci) AS `folio`,cast(`p`.`actualizado_en` as date) AS `fecha`,cast(`p`.`actualizado_en` as time) AS `hora`,`p`.`total_estimado` AS `total`,(convert(`p`.`metodo_pago` using utf8mb4) collate utf8mb4_0900_ai_ci) AS `metodo_pago`,('completada' collate utf8mb4_0900_ai_ci) AS `estado`,`u`.`nombre_completo` AS `vendedor`,coalesce(sum(`dp`.`cantidad`),0) AS `total_piezas` from ((`pedidos` `p` join `usuarios` `u` on((`u`.`id_usuario` = coalesce(`p`.`atendido_por`,1)))) left join `detalle_pedidos` `dp` on((`dp`.`id_pedido` = `p`.`id_pedido`))) where (((convert(`p`.`estado` using utf8mb4) collate utf8mb4_0900_ai_ci) = ('entregado' collate utf8mb4_0900_ai_ci)) and exists(select 1 from `logs_sistema` `l` where ((`l`.`referencia_id` = `p`.`id_pedido`) and (`l`.`referencia_tipo` = 'pedido') and (`l`.`accion` = 'venta_automatica'))) is false) group by `p`.`id_pedido`,`p`.`folio`,`p`.`actualizado_en`,`p`.`total_estimado`,`p`.`metodo_pago`,`p`.`estado`,`u`.`nombre_completo` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_dash_mp_criticas`
--

/*!50001 DROP VIEW IF EXISTS `vw_dash_mp_criticas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_dash_mp_criticas` AS select `materias_primas`.`id_materia` AS `id_materia`,`materias_primas`.`nombre` AS `nombre`,coalesce(`materias_primas`.`categoria`,'Sin categoría') AS `categoria`,`materias_primas`.`unidad_base` AS `unidad_base`,`materias_primas`.`stock_actual` AS `stock_actual`,`materias_primas`.`stock_minimo` AS `stock_minimo`,round((case when (`materias_primas`.`stock_minimo` > 0) then ((`materias_primas`.`stock_actual` / `materias_primas`.`stock_minimo`) * 100) else 100 end),1) AS `pct_stock`,(case when (`materias_primas`.`stock_actual` = 0) then 'critico' when (`materias_primas`.`stock_actual` < (`materias_primas`.`stock_minimo` * 0.5)) then 'bajo' else 'advertencia' end) AS `nivel` from `materias_primas` where ((`materias_primas`.`estatus` = 'activo') and (`materias_primas`.`stock_minimo` > 0) and (`materias_primas`.`stock_actual` <= `materias_primas`.`stock_minimo`)) order by round((case when (`materias_primas`.`stock_minimo` > 0) then ((`materias_primas`.`stock_actual` / `materias_primas`.`stock_minimo`) * 100) else 100 end),1) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_dash_piezas_vendidas`
--

/*!50001 DROP VIEW IF EXISTS `vw_dash_piezas_vendidas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_dash_piezas_vendidas` AS select `dv`.`id_producto` AS `id_producto`,`dv`.`cantidad` AS `cantidad`,`dv`.`subtotal` AS `subtotal`,cast(`v`.`fecha_venta` as date) AS `fecha` from (`detalle_ventas` `dv` join `ventas` `v` on((`v`.`id_venta` = `dv`.`id_venta`))) where ((`v`.`estado` = 'completada') and (`dv`.`id_producto` is not null)) union all select `dp`.`id_producto` AS `id_producto`,`dp`.`cantidad` AS `cantidad`,`dp`.`subtotal` AS `subtotal`,cast(`p`.`actualizado_en` as date) AS `fecha` from (`detalle_pedidos` `dp` join `pedidos` `p` on((`p`.`id_pedido` = `dp`.`id_pedido`))) where (((convert(`p`.`estado` using utf8mb4) collate utf8mb4_0900_ai_ci) = 'entregado') and exists(select 1 from `logs_sistema` `l` where ((`l`.`referencia_id` = `p`.`id_pedido`) and (`l`.`referencia_tipo` = 'pedido') and (`l`.`accion` = 'venta_automatica'))) is false) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_dash_ventas_consolidadas`
--

/*!50001 DROP VIEW IF EXISTS `vw_dash_ventas_consolidadas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_dash_ventas_consolidadas` AS select `v`.`id_venta` AS `origen_id`,'venta' AS `origen_tipo`,cast(`v`.`fecha_venta` as date) AS `fecha`,`v`.`total` AS `monto` from `ventas` `v` where (`v`.`estado` = 'completada') union all select `p`.`id_pedido` AS `origen_id`,'pedido' AS `origen_tipo`,cast(`p`.`actualizado_en` as date) AS `fecha`,`p`.`total_estimado` AS `monto` from `pedidos` `p` where (((convert(`p`.`estado` using utf8mb4) collate utf8mb4_0900_ai_ci) = 'entregado') and exists(select 1 from `logs_sistema` `l` where ((`l`.`referencia_id` = `p`.`id_pedido`) and (`l`.`referencia_tipo` = 'pedido') and (`l`.`accion` = 'venta_automatica'))) is false) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_materias_primas`
--

/*!50001 DROP VIEW IF EXISTS `vw_materias_primas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_materias_primas` AS select `mp`.`id_materia` AS `id_materia`,`mp`.`uuid_materia` AS `uuid_materia`,`mp`.`nombre` AS `nombre`,`mp`.`categoria` AS `categoria`,`mp`.`unidad_base` AS `unidad_base`,`mp`.`stock_actual` AS `stock_actual`,`mp`.`stock_minimo` AS `stock_minimo`,`mp`.`estatus` AS `estatus`,`mp`.`creado_en` AS `creado_en`,`mp`.`actualizado_en` AS `actualizado_en`,(case when (`mp`.`stock_actual` <= 0) then 'critico' when ((`mp`.`stock_actual` > 0) and (`mp`.`stock_actual` <= `mp`.`stock_minimo`)) then 'bajo' else 'normal' end) AS `nivel_stock` from `materias_primas` `mp` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_produccion_diaria`
--

/*!50001 DROP VIEW IF EXISTS `vw_produccion_diaria`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_produccion_diaria` AS select `pd`.`id_pd` AS `id_pd`,`pd`.`folio` AS `folio`,`pd`.`nombre` AS `nombre`,`pd`.`estado` AS `estado`,`pd`.`total_cajas` AS `total_cajas`,`pd`.`total_piezas_esperadas` AS `total_piezas_esperadas`,`pd`.`alerta_insumos` AS `alerta_insumos`,`pd`.`insumos_descontados` AS `insumos_descontados`,`pd`.`inventario_acreditado` AS `inventario_acreditado`,`pd`.`observaciones` AS `observaciones`,`pd`.`motivo_cancelacion` AS `motivo_cancelacion`,`pd`.`fecha_inicio` AS `fecha_inicio`,`pd`.`fecha_fin_real` AS `fecha_fin_real`,`pd`.`creado_en` AS `creado_en`,`pd`.`actualizado_en` AS `actualizado_en`,`pd`.`operario_id` AS `operario_id`,`u_op`.`nombre_completo` AS `operario`,`pd`.`creado_por` AS `creado_por`,`u_cr`.`nombre_completo` AS `creado_por_nombre`,count(distinct `pdd`.`id_pdd`) AS `total_lineas` from (((`produccion_diaria` `pd` left join `usuarios` `u_op` on((`u_op`.`id_usuario` = `pd`.`operario_id`))) left join `usuarios` `u_cr` on((`u_cr`.`id_usuario` = `pd`.`creado_por`))) left join `produccion_diaria_detalle` `pdd` on((`pdd`.`id_pd` = `pd`.`id_pd`))) group by `pd`.`id_pd`,`pd`.`folio`,`pd`.`nombre`,`pd`.`estado`,`pd`.`total_cajas`,`pd`.`total_piezas_esperadas`,`pd`.`alerta_insumos`,`pd`.`insumos_descontados`,`pd`.`inventario_acreditado`,`pd`.`observaciones`,`pd`.`motivo_cancelacion`,`pd`.`fecha_inicio`,`pd`.`fecha_fin_real`,`pd`.`creado_en`,`pd`.`actualizado_en`,`pd`.`operario_id`,`u_op`.`nombre_completo`,`pd`.`creado_por`,`u_cr`.`nombre_completo` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_productos`
--

/*!50001 DROP VIEW IF EXISTS `vw_productos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_productos` AS select `p`.`id_producto` AS `id_producto`,`p`.`uuid_producto` AS `uuid_producto`,`p`.`nombre` AS `nombre`,`p`.`descripcion` AS `descripcion`,`p`.`imagen_url` AS `imagen_url`,`p`.`precio_venta` AS `precio_venta`,`p`.`estatus` AS `estatus`,`p`.`creado_en` AS `creado_en`,`p`.`actualizado_en` AS `actualizado_en`,ifnull(`inv`.`stock_actual`,0) AS `stock_actual`,ifnull(`inv`.`stock_minimo`,0) AS `stock_minimo`,ifnull(`rec`.`total_recetas`,0) AS `total_recetas` from ((`productos` `p` left join `inventario_pt` `inv` on((`inv`.`id_producto` = `p`.`id_producto`))) left join (select `recetas`.`id_producto` AS `id_producto`,count(0) AS `total_recetas` from `recetas` where (`recetas`.`id_producto` is not null) group by `recetas`.`id_producto`) `rec` on((`rec`.`id_producto` = `p`.`id_producto`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_productos_stock`
--

/*!50001 DROP VIEW IF EXISTS `vw_productos_stock`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_productos_stock` AS select `p`.`id_producto` AS `id_producto`,`p`.`uuid_producto` AS `uuid_producto`,`p`.`nombre` AS `nombre`,`p`.`descripcion` AS `descripcion`,`p`.`imagen_url` AS `imagen_url`,`p`.`precio_venta` AS `precio_venta`,`p`.`estatus` AS `estatus`,coalesce(`i`.`stock_actual`,0) AS `stock_actual`,coalesce(`i`.`stock_minimo`,0) AS `stock_minimo`,(case when (coalesce(`i`.`stock_actual`,0) <= 0) then 'agotado' when (coalesce(`i`.`stock_actual`,0) <= coalesce(`i`.`stock_minimo`,0)) then 'bajo' else 'disponible' end) AS `estado_stock` from (`productos` `p` left join `inventario_pt` `i` on((`i`.`id_producto` = `p`.`id_producto`))) where (`p`.`estatus` = 'activo') */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_recetas`
--

/*!50001 DROP VIEW IF EXISTS `vw_recetas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_recetas` AS select `r`.`id_receta` AS `id_receta`,`r`.`uuid_receta` AS `uuid_receta`,`r`.`nombre` AS `nombre`,`r`.`descripcion` AS `descripcion`,`r`.`id_producto` AS `id_producto`,`p`.`nombre` AS `producto_nombre`,`r`.`rendimiento` AS `rendimiento`,`r`.`unidad_rendimiento` AS `unidad_rendimiento`,`r`.`precio_venta` AS `precio_venta`,`r`.`estatus` AS `estatus`,`r`.`creado_en` AS `creado_en`,`r`.`actualizado_en` AS `actualizado_en`,`r`.`creado_por` AS `creado_por`,ifnull(`ins`.`total_insumos`,0) AS `total_insumos` from ((`recetas` `r` left join `productos` `p` on((`p`.`id_producto` = `r`.`id_producto`))) left join (select `detalle_recetas`.`id_receta` AS `id_receta`,count(distinct `detalle_recetas`.`id_materia`) AS `total_insumos` from `detalle_recetas` group by `detalle_recetas`.`id_receta`) `ins` on((`ins`.`id_receta` = `r`.`id_receta`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_salidas_efectivo`
--

/*!50001 DROP VIEW IF EXISTS `vw_salidas_efectivo`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_salidas_efectivo` AS select `s`.`id_salida` AS `id_salida`,`s`.`folio_salida` AS `folio_salida`,`s`.`id_proveedor` AS `id_proveedor`,`p`.`nombre` AS `nombre_proveedor`,`s`.`id_compra` AS `id_compra`,`c`.`folio` AS `folio_compra`,`s`.`categoria` AS `categoria`,`s`.`descripcion` AS `descripcion`,`s`.`monto` AS `monto`,`s`.`fecha_salida` AS `fecha_salida`,`s`.`estado` AS `estado`,`s`.`registrado_por` AS `registrado_por`,`u1`.`nombre_completo` AS `nombre_registrador`,`s`.`aprobado_por` AS `aprobado_por`,`u2`.`nombre_completo` AS `nombre_aprobador`,`s`.`creado_en` AS `creado_en`,`s`.`actualizado_en` AS `actualizado_en` from ((((`salidas_efectivo` `s` left join `proveedores` `p` on((`s`.`id_proveedor` = `p`.`id_proveedor`))) left join `compras` `c` on((`s`.`id_compra` = `c`.`id_compra`))) join `usuarios` `u1` on((`s`.`registrado_por` = `u1`.`id_usuario`))) left join `usuarios` `u2` on((`s`.`aprobado_por` = `u2`.`id_usuario`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_top_productos_vendidos`
--

/*!50001 DROP VIEW IF EXISTS `vw_top_productos_vendidos`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_top_productos_vendidos` AS select `p`.`id_producto` AS `id_producto`,`p`.`nombre` AS `nombre`,`p`.`precio_venta` AS `precio_venta`,coalesce(sum(`dv`.`cantidad`),0) AS `ventas_caja`,coalesce(`web_vendidos`.`total_web`,0) AS `ventas_web`,(coalesce(sum(`dv`.`cantidad`),0) + coalesce(`web_vendidos`.`total_web`,0)) AS `total_vendido` from (((`productos` `p` left join `detalle_ventas` `dv` on((`dv`.`id_producto` = `p`.`id_producto`))) left join `ventas` `v` on(((`v`.`id_venta` = `dv`.`id_venta`) and (`v`.`estado` = 'completada')))) left join (select `dp`.`id_producto` AS `id_producto`,sum(`dp`.`cantidad`) AS `total_web` from (`detalle_pedidos` `dp` join `pedidos` `p2` on((`p2`.`id_pedido` = `dp`.`id_pedido`))) where (`p2`.`estado` = 'entregado') group by `dp`.`id_producto`) `web_vendidos` on((`web_vendidos`.`id_producto` = `p`.`id_producto`))) where (`p`.`estatus` = 'activo') group by `p`.`id_producto`,`p`.`nombre`,`p`.`precio_venta`,`web_vendidos`.`total_web` order by `total_vendido` desc */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_usuarios`
--

/*!50001 DROP VIEW IF EXISTS `vw_usuarios`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`dm_restore`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_usuarios` AS select `u`.`id_usuario` AS `id_usuario`,`u`.`nombre_completo` AS `nombre_completo`,`u`.`telefono` AS `telefono`,`u`.`username` AS `username`,`u`.`id_rol` AS `id_rol`,`r`.`nombre_rol` AS `nombre_rol`,`r`.`clave_rol` AS `clave_rol`,`u`.`estatus` AS `estatus`,`u`.`ultimo_login` AS `ultimo_login`,`u`.`creado_en` AS `creado_en` from (`usuarios` `u` left join `roles` `r` on((`u`.`id_rol` = `r`.`id_rol`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_ventas_caja`
--

/*!50001 DROP VIEW IF EXISTS `vw_ventas_caja`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_ventas_caja` AS select `v`.`id_venta` AS `id_venta`,`v`.`folio_venta` AS `folio_venta`,`v`.`fecha_venta` AS `fecha_venta`,`v`.`total` AS `total`,`v`.`metodo_pago` AS `metodo_pago`,`v`.`cambio` AS `cambio`,`v`.`estado` AS `estado`,`v`.`vendedor_id` AS `vendedor_id`,`u`.`nombre_completo` AS `vendedor_nombre`,count(`dv`.`id_detalle_venta`) AS `num_productos`,coalesce(sum(`dv`.`cantidad`),0) AS `total_piezas`,coalesce(sum(`dv`.`subtotal`),0) AS `total_venta`,(case when exists(select 1 from `tickets` `t` where (`t`.`id_venta` = `v`.`id_venta`)) then 1 else 0 end) AS `ticket_impreso` from ((`ventas` `v` join `usuarios` `u` on((`u`.`id_usuario` = `v`.`vendedor_id`))) left join `detalle_ventas` `dv` on((`dv`.`id_venta` = `v`.`id_venta`))) where (`v`.`estado` = 'completada') group by `v`.`id_venta`,`v`.`folio_venta`,`v`.`fecha_venta`,`v`.`total`,`v`.`metodo_pago`,`v`.`cambio`,`v`.`estado`,`v`.`vendedor_id`,`u`.`nombre_completo` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_ventas_consolidadas`
--

/*!50001 DROP VIEW IF EXISTS `vw_ventas_consolidadas`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_ventas_consolidadas` AS select 'caja' AS `origen`,`v`.`id_venta` AS `id`,`v`.`folio_venta` AS `folio`,`v`.`fecha_venta` AS `fecha`,`v`.`total` AS `total`,(convert(`v`.`metodo_pago` using utf8mb4) collate utf8mb4_unicode_ci) AS `metodo_pago`,(convert(`v`.`estado` using utf8mb4) collate utf8mb4_unicode_ci) AS `estado`,`u`.`nombre_completo` AS `responsable`,NULL AS `pedido_origen` from (`ventas` `v` join `usuarios` `u` on((`u`.`id_usuario` = `v`.`vendedor_id`))) where ((`v`.`estado` = 'completada') and exists(select 1 from `logs_sistema` `l` where ((`l`.`referencia_id` = `v`.`id_venta`) and (`l`.`referencia_tipo` = 'venta') and (`l`.`accion` = 'venta_automatica'))) is false) union all select 'pedido_web' AS `origen`,`p`.`id_pedido` AS `id`,concat('PED-',convert(lpad(`p`.`id_pedido`,4,'0') using utf8mb4)) AS `folio`,`p`.`actualizado_en` AS `fecha`,`p`.`total_estimado` AS `total`,(convert(`p`.`metodo_pago` using utf8mb4) collate utf8mb4_unicode_ci) AS `metodo_pago`,(convert(`p`.`estado` using utf8mb4) collate utf8mb4_unicode_ci) AS `estado`,`u`.`nombre_completo` AS `responsable`,`p`.`folio` AS `pedido_origen` from (`pedidos` `p` join `usuarios` `u` on((`u`.`id_usuario` = coalesce(`p`.`atendido_por`,1)))) where ((`p`.`estado` = 'entregado') and exists(select 1 from `logs_sistema` `l` where ((`l`.`referencia_id` = `p`.`id_pedido`) and (`l`.`referencia_tipo` = 'pedido') and (`l`.`accion` = 'venta_automatica'))) is false) order by `fecha` desc */;
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

-- Dump completed on 2026-04-16  1:59:24
